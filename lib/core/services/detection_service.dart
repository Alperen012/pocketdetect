import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../detection/letterbox.dart';
import '../detection/nms.dart';
import '../detection/yolo_decoder.dart';
import '../models/app_settings.dart';
import '../models/detected_object.dart';
import '../models/resolution_profile.dart';

// ---------------------------------------------------------------------------
// Isolate message types — must be top-level so compute() can send/receive them
// ---------------------------------------------------------------------------

class _PreprocessMessage {
  const _PreprocessMessage({
    required this.rgbBytes,
    required this.width,
    required this.height,
    required this.isInt8,
    required this.scale,
    required this.zeroPoint,
  });

  final Uint8List rgbBytes;
  final int width;
  final int height;
  final bool isInt8;
  final double scale;
  final int zeroPoint;
}

/// Builds the model input tensor in a background isolate.
/// Returns `List<List<List<List<T>>>>` where T is int (int8) or double (float32).
Object _buildInputFromBytes(_PreprocessMessage msg) {
  final w = msg.width;
  final h = msg.height;
  final bytes = msg.rgbBytes;
  final s = msg.scale;
  final zp = msg.zeroPoint;

  if (msg.isInt8) {
    return List<List<List<List<int>>>>.generate(
      1,
      (_) => List<List<List<int>>>.generate(
        h,
        (y) => List<List<int>>.generate(w, (x) {
          final idx = (y * w + x) * 3;
          return <int>[
            (bytes[idx] / 255.0 / s + zp).round(),
            (bytes[idx + 1] / 255.0 / s + zp).round(),
            (bytes[idx + 2] / 255.0 / s + zp).round(),
          ];
        }),
      ),
    );
  }

  return List<List<List<List<double>>>>.generate(
    1,
    (_) => List<List<List<double>>>.generate(
      h,
      (y) => List<List<double>>.generate(w, (x) {
        final idx = (y * w + x) * 3;
        return <double>[
          bytes[idx] / 255.0,
          bytes[idx + 1] / 255.0,
          bytes[idx + 2] / 255.0,
        ];
      }),
    ),
  );
}

class DetectionService extends ChangeNotifier {
  DetectionService();

  Interpreter? _interpreter;
  List<String> _labels = <String>[];
  String? _error;
  String? _activeModelPath;
  String? _activeLabelsPath;
  bool _usingCustomModel = false;
  int _lastInferenceMs = 0;
  bool _isLoading = false;
  AppSettings? _pendingSettings;

  bool get isReady => _interpreter != null && _labels.isNotEmpty;
  String? get error => _error;
  /// Wall-clock time of the last `interpreter.run()` call in milliseconds.
  int get lastInferenceMs => _lastInferenceMs;

  Future<void> initialize({required AppSettings settings}) async {
    await _loadFromSettings(settings, force: true);
  }

  Future<void> reloadIfNeeded(AppSettings settings) async {
    // If a load is in progress, save these settings so they can be applied
    // once the current load completes.
    if (_isLoading) {
      _pendingSettings = settings;
      return;
    }
    final modelPath = settings.useCustomModel ? settings.customModelPath : null;
    final labelsPath = settings.useCustomModel ? settings.customLabelsPath : null;
    final shouldReload = _usingCustomModel != settings.useCustomModel ||
        _activeModelPath != modelPath ||
        _activeLabelsPath != labelsPath ||
        !isReady;
    if (!shouldReload) {
      return;
    }
    await _loadFromSettings(settings, force: true);
  }

  /// Runs detection on an image file.
  Future<List<DetectedObject>> detectObjects({
    required File imageFile,
    required ResolutionProfile profile,
    required double confidence,
    required double iou,
    required bool useNms,
    required int maxDetections,
    required Set<String> selectedLabels,
    bool filterBySelectedLabels = true,
  }) async {
    // Snapshot the interpreter so a concurrent reload cannot null it under us.
    final interpreter = _interpreter;
    if (interpreter == null || _labels.isEmpty) {
      return <DetectedObject>[];
    }
    // Capture labels list reference so a concurrent reload cannot swap it.
    final labels = List<String>.unmodifiable(_labels);

    await Future<void>.delayed(Duration.zero);

    // Guard against missing or unreadable image files (e.g. temp file deleted
    // by the OS between pick and detection).
    if (!await imageFile.exists()) {
      return <DetectedObject>[];
    }

    final Uint8List bytes;
    try {
      bytes = await imageFile.readAsBytes();
    } on FileSystemException {
      return <DetectedObject>[];
    }

    await Future<void>.delayed(Duration.zero);
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return <DetectedObject>[];
    }

    return _detect(
      interpreter: interpreter,
      labels: labels,
      image: decoded,
      profile: profile,
      confidence: confidence,
      iouThreshold: iou,
      useNms: useNms,
      maxDetections: maxDetections,
      selectedLabels: selectedLabels,
      filterBySelectedLabels: filterBySelectedLabels,
    );
  }

  /// Runs detection on an already-decoded [img.Image].
  ///
  /// This is intended for real-time camera pipelines where the caller converts
  /// `CameraImage` → `img.Image` beforehand.  Skips file I/O for speed.
  Future<List<DetectedObject>> detectFromImage({
    required img.Image image,
    required ResolutionProfile profile,
    required double confidence,
    required double iou,
    required bool useNms,
    required int maxDetections,
    required Set<String> selectedLabels,
    bool filterBySelectedLabels = true,
  }) async {
    final interpreter = _interpreter;
    if (interpreter == null || _labels.isEmpty) {
      return <DetectedObject>[];
    }
    return _detect(
      interpreter: interpreter,
      labels: List<String>.unmodifiable(_labels),
      image: image,
      profile: profile,
      confidence: confidence,
      iouThreshold: iou,
      useNms: useNms,
      maxDetections: maxDetections,
      selectedLabels: selectedLabels,
      filterBySelectedLabels: filterBySelectedLabels,
    );
  }

  /// Shared detection pipeline for file and camera-frame input.
  ///
  /// [interpreter] and [labels] are snapshots taken by the caller so a
  /// concurrent model reload cannot swap them mid-run.
  Future<List<DetectedObject>> _detect({
    required Interpreter interpreter,
    required List<String> labels,
    required img.Image image,
    required ResolutionProfile profile,
    required double confidence,
    required double iouThreshold,
    required bool useNms,
    required int maxDetections,
    required Set<String> selectedLabels,
    required bool filterBySelectedLabels,
  }) async {
    final inputTensor = interpreter.getInputTensor(0);
    final modelInputSize = inputTensor.shape[1];

    // Pre-downscale very large images using profile resolution as a cap.
    var source = image;
    final capped = capLongestSide(image.width, image.height, profile.size);
    if (capped.width != image.width || capped.height != image.height) {
      source = img.copyResize(
        image,
        width: capped.width,
        height: capped.height,
        interpolation: img.Interpolation.linear,
      );
    }

    // Letterbox preprocessing (preserves aspect ratio).
    final letterbox = LetterboxParams.compute(
      sourceWidth: source.width,
      sourceHeight: source.height,
      inputSize: modelInputSize,
    );

    final resized = img.copyResize(
      source,
      width: letterbox.scaledWidth,
      height: letterbox.scaledHeight,
      interpolation: img.Interpolation.linear,
    );

    // Padded square canvas (YOLO letterbox standard: gray 114).
    final processed = img.Image(width: modelInputSize, height: modelInputSize);
    for (var py = 0; py < modelInputSize; py++) {
      for (var px = 0; px < modelInputSize; px++) {
        processed.setPixelRgba(px, py, 114, 114, 114, 255);
      }
    }
    for (var py = 0; py < letterbox.scaledHeight; py++) {
      for (var px = 0; px < letterbox.scaledWidth; px++) {
        processed.setPixel(
          letterbox.padX + px,
          letterbox.padY + py,
          resized.getPixel(px, py),
        );
      }
    }

    final outputTensor = interpreter.getOutputTensor(0);
    final inputParams = inputTensor.params;
    final isInt8 = inputTensor.type == TensorType.int8;

    // Step 1: Build input buffer in background isolate (pixel loop is off main thread).
    final rgbBytes = processed.getBytes(order: img.ChannelOrder.rgb);
    final inputBuffer = await compute(
      _buildInputFromBytes,
      _PreprocessMessage(
        rgbBytes: rgbBytes,
        width: modelInputSize,
        height: modelInputSize,
        isInt8: isInt8,
        scale: inputParams.scale,
        zeroPoint: inputParams.zeroPoint,
      ),
    );

    // Step 2: Run inference on main thread (interpreter holds native resources).
    // Re-check that the interpreter wasn't replaced during the await above.
    if (_interpreter != interpreter) {
      return <DetectedObject>[];
    }
    final output = _buildOutputBuffer(outputTensor);
    final sw = Stopwatch()..start();
    interpreter.run(inputBuffer, output);
    sw.stop();
    _lastInferenceMs = sw.elapsedMilliseconds;

    // Step 3: Parse quantized output (fast, stays on main thread).
    final outputData = _parseOutput(outputTensor, output);

    // Step 4: Decode detections in background isolate.
    final rawDetections = await compute(
      decodeYolo,
      DecodeRequest(
        output: outputData,
        letterbox: letterbox,
        confidence: confidence,
        labels: labels,
        selectedLabels: selectedLabels.toList(),
        filterBySelected: filterBySelectedLabels,
      ),
    );

    // DetectedObject needs dart:ui Rect — rebuild on the main isolate.
    final detections = rawDetections
        .map(
          (raw) => DetectedObject(
            label: raw.label,
            confidence: raw.score,
            boundingBox: Rect.fromLTWH(raw.left, raw.top, raw.width, raw.height),
          ),
        )
        .toList();

    if (!useNms) {
      return detections.take(maxDetections).toList();
    }

    return nonMaxSuppression(detections, iouThreshold, maxDetections);
  }

  Future<void> _loadFromSettings(AppSettings settings, {required bool force}) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    try {
      if (!force && isReady) {
        return;
      }

      _interpreter?.close();
      _interpreter = null;

      final useCustom = settings.useCustomModel;
      final modelPath = settings.customModelPath;
      final labelsPath = settings.customLabelsPath;

      if (useCustom && (modelPath == null || modelPath.isEmpty)) {
        throw StateError('Custom model enabled but no .tflite file selected.');
      }

      _labels = await _loadLabels(labelsPath, useCustom);
      final freshInterpreter = await _createInterpreter(modelPath, useCustom);
      _interpreter = freshInterpreter;
      _validateModelCompatibility(
        freshInterpreter,
        labels: _labels,
        hasCustomLabels: useCustom && labelsPath != null && labelsPath.isNotEmpty,
      );
      _error = null;
      _usingCustomModel = useCustom;
      _activeModelPath = useCustom ? modelPath : null;
      _activeLabelsPath = useCustom ? labelsPath : null;
      notifyListeners();
    } catch (err) {
      _error = 'Failed to load model: $err';
      _interpreter = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      // If settings changed while we were loading, apply them now.
      final pending = _pendingSettings;
      if (pending != null) {
        _pendingSettings = null;
        await reloadIfNeeded(pending);
      }
    }
  }

  void _validateModelCompatibility(
    Interpreter interpreter, {
    required List<String> labels,
    required bool hasCustomLabels,
  }) {
    final input = interpreter.getInputTensor(0);
    final output = interpreter.getOutputTensor(0);

    final inputShape = input.shape;
    if (inputShape.length != 4 || inputShape[0] != 1 || inputShape[3] != 3) {
      throw StateError(
        'Unsupported input tensor shape: $inputShape. Expected [1, H, W, 3].',
      );
    }

    if (input.type != TensorType.int8 && input.type != TensorType.float32) {
      throw StateError(
        'Unsupported input tensor type: ${input.type}. Expected int8 or float32.',
      );
    }

    final outputShape = output.shape;
    if (outputShape.length != 3 || outputShape[0] != 1 || outputShape[1] < 5) {
      throw StateError(
        'Unsupported output tensor shape: $outputShape. Expected [1, C, N] with C >= 5.',
      );
    }

    if (output.type != TensorType.int8 && output.type != TensorType.float32) {
      throw StateError(
        'Unsupported output tensor type: ${output.type}. Expected int8 or float32.',
      );
    }

    if (hasCustomLabels) {
      final classCount = outputShape[1] - 4;
      if (labels.length != classCount) {
        throw StateError(
          'Labels count (${labels.length}) does not match model class count ($classCount).',
        );
      }
    }
  }

  Future<List<String>> _loadLabels(String? labelsPath, bool useCustom) async {
    if (useCustom && labelsPath != null && labelsPath.isNotEmpty) {
      final file = File(labelsPath);
      final raw = await file.readAsString();
      return raw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }

    final raw = await rootBundle.loadString('assets/labels/coco.txt');
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<Interpreter> _createInterpreter(String? modelPath, bool useCustom) async {
    const modelAssetPath = 'assets/models/yolo26n_int8.tflite';

    // Attempt 1: NNAPI (Android hardware accelerator).
    try {
      final nnOptions = InterpreterOptions()..useNnApiForAndroid = true;
      return await _loadInterpreterWithOptions(
        nnOptions,
        modelPath,
        useCustom,
        modelAssetPath,
      );
    } catch (_) {}

    // Attempt 2: GPU delegate — use a fresh options object so no
    // stale NNAPI flag leaks in.
    GpuDelegateV2? gpuDelegate;
    try {
      gpuDelegate = GpuDelegateV2();
      final gpuOptions = InterpreterOptions()..addDelegate(gpuDelegate);
      return await _loadInterpreterWithOptions(
        gpuOptions,
        modelPath,
        useCustom,
        modelAssetPath,
      );
    } catch (_) {
      gpuDelegate?.delete();
    }

    // Attempt 3: CPU fallback.
    if (useCustom && modelPath != null && modelPath.isNotEmpty) {
      return Interpreter.fromFile(File(modelPath));
    }

    return Interpreter.fromAsset(modelAssetPath);
  }

  Future<Interpreter> _loadInterpreterWithOptions(
    InterpreterOptions options,
    String? modelPath,
    bool useCustom,
    String modelAssetPath,
  ) async {
    if (useCustom && modelPath != null && modelPath.isNotEmpty) {
      return Interpreter.fromFile(File(modelPath), options: options);
    }
    return Interpreter.fromAsset(modelAssetPath, options: options);
  }

  Object _buildOutputBuffer(Tensor outputTensor) {
    final shape = outputTensor.shape;
    final channels = shape[1];
    final count = shape[2];

    if (outputTensor.type == TensorType.int8) {
      return List.generate(
        1,
        (_) => List.generate(channels, (_) => List.filled(count, 0)),
      );
    }

    return List.generate(
      1,
      (_) => List.generate(channels, (_) => List.filled(count, 0.0)),
    );
  }

  List<List<double>> _parseOutput(Tensor outputTensor, Object outputBuffer) {
    final params = outputTensor.params;
    final raw = outputBuffer as List;
    final List<List<double>> decoded = <List<double>>[];
    for (final channel in raw[0] as List) {
      final values = <double>[];
      for (final value in channel as List) {
        if (outputTensor.type == TensorType.int8) {
          values.add(_dequantize(value as int, params));
        } else {
          values.add((value as num).toDouble());
        }
      }
      decoded.add(values);
    }
    return decoded;
  }

  double _dequantize(int value, QuantizationParams params) {
    return (value - params.zeroPoint) * params.scale;
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
