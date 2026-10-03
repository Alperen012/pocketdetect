import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../detection/image_decode.dart';
import '../detection/interpreter_factory.dart';
import '../detection/letterbox.dart';
import '../detection/nms.dart';
import '../detection/tensor_io.dart';
import '../detection/yolo_decoder.dart';
import '../models/detected_object.dart';
import '../models/installed_model.dart';
import '../models/resolution_profile.dart';

class DetectionService extends ChangeNotifier {
  DetectionService();

  Interpreter? _interpreter;
  List<String> _labels = <String>[];
  String? _error;
  InstalledModel? _activeModel;
  int _lastInferenceMs = 0;
  bool _isLoading = false;
  InstalledModel? _pendingModel;

  DelegateKind? _activeDelegate;
  Map<DelegateKind, Object> _delegateFailures = const <DelegateKind, Object>{};

  bool get isReady => _interpreter != null && _labels.isNotEmpty;
  String? get error => _error;

  /// Which hardware path the loaded model actually runs on.
  DelegateKind? get activeDelegate => _activeDelegate;

  /// Delegates that were tried first but could not load, with the reason.
  Map<DelegateKind, Object> get delegateFailures =>
      Map<DelegateKind, Object>.unmodifiable(_delegateFailures);

  /// Wall-clock time of the last `interpreter.run()` call in milliseconds.
  int get lastInferenceMs => _lastInferenceMs;

  /// The model currently loaded (or last attempted).
  InstalledModel? get activeModel => _activeModel;

  Future<void> initialize({required InstalledModel model}) async {
    await _loadModel(model);
  }

  /// Loads [model] unless it is already the loaded one.
  Future<void> reloadIfNeeded(InstalledModel model) async {
    // If a load is in progress, remember the request so it can be applied
    // once the current load completes.
    if (_isLoading) {
      _pendingModel = model;
      return;
    }
    final active = _activeModel;
    final sameModel =
        active != null &&
        active.id == model.id &&
        active.filePath == model.filePath;
    if (sameModel && isReady) {
      return;
    }
    await _loadModel(model);
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
    final decoded = decodeUpright(bytes);
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

    final inputParams = inputTensor.params;
    final isInt8 = inputTensor.type == TensorType.int8;

    // Step 1: Build the flat input tensor in a background isolate.
    final rgbBytes = processed.getBytes(order: img.ChannelOrder.rgb);
    final inputBytes = await compute(
      buildInputBytes,
      InputBuildRequest(
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
    final sw = Stopwatch()..start();
    interpreter.runInference(<Object>[inputBytes]);
    sw.stop();
    _lastInferenceMs = sw.elapsedMilliseconds;

    // Step 3: Read the output tensor (copied out of native memory, which the
    // next run overwrites) and split/dequantize it per channel.
    final outputTensor = interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final outputParams = outputTensor.params;
    final outputData = parseOutputBytes(
      Uint8List.fromList(outputTensor.data),
      isInt8: outputTensor.type == TensorType.int8,
      channels: outputShape[1],
      count: outputShape[2],
      scale: outputParams.scale,
      zeroPoint: outputParams.zeroPoint,
    );

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
            boundingBox: Rect.fromLTWH(
              raw.left,
              raw.top,
              raw.width,
              raw.height,
            ),
          ),
        )
        .toList();

    if (!useNms) {
      return detections.take(maxDetections).toList();
    }

    return nonMaxSuppression(detections, iouThreshold, maxDetections);
  }

  Future<void> _loadModel(InstalledModel model) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    try {
      _interpreter?.close();
      _interpreter = null;
      _activeModel = model;

      _labels = await _loadLabels(model);
      final freshInterpreter = await _createInterpreter(model);
      _interpreter = freshInterpreter;
      _validateModelCompatibility(
        freshInterpreter,
        labels: _labels,
        // Bundled COCO names are trusted; explicit lists must match the model.
        checkLabelCount: model.labels.isNotEmpty,
      );
      _error = null;
      notifyListeners();
    } catch (err) {
      _error = 'Failed to load model: $err';
      _interpreter = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      // If another model was requested while loading, apply it now.
      final pending = _pendingModel;
      if (pending != null) {
        _pendingModel = null;
        await reloadIfNeeded(pending);
      }
    }
  }

  void _validateModelCompatibility(
    Interpreter interpreter, {
    required List<String> labels,
    required bool checkLabelCount,
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

    if (checkLabelCount) {
      final classCount = outputShape[1] - 4;
      if (labels.length != classCount) {
        throw StateError(
          'Labels count (${labels.length}) does not match model class count ($classCount).',
        );
      }
    }
  }

  Future<List<String>> _loadLabels(InstalledModel model) async {
    if (model.labels.isNotEmpty) {
      return List<String>.of(model.labels);
    }

    final raw = await rootBundle.loadString('assets/labels/coco.txt');
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<Interpreter> _createInterpreter(InstalledModel model) async {
    final filePath = model.filePath;
    final source = filePath != null
        ? ModelSource.file(filePath)
        : ModelSource.asset(model.assetPath!);

    final result = await createInterpreter(source);
    _activeDelegate = result.delegate;
    _delegateFailures = result.failures;
    return result.interpreter;
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
