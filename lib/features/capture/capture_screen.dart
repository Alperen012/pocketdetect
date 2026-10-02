import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/detected_object.dart';
import '../../core/services/detection_service.dart';
import '../../core/services/device_capabilities.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../results/results_screen.dart';
import '../preferences/preferences_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/bounding_box_overlay.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final DeviceCapabilities _deviceCapabilities = const DeviceCapabilities();
  bool _lowMemoryDevice = false;
  bool _checkedLowMemory = false;
  CameraController? _cameraController;
  Future<void>? _cameraInit;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _selectedCamera = 0;
  bool _initializingCamera = false;

  // --- Live detection state ---
  bool _isLiveMode = false;
  bool _isProcessingFrame = false;
  List<DetectedObject> _liveDetections = <DetectedObject>[];
  double _fps = 0;
  int _inferenceMs = 0;
  int _frameCount = 0;
  DateTime _fpsTimestamp = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkLowMemory();
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(CaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopLiveDetection();
      _cameraController?.dispose();
      _cameraController = null;
      _cameraInit = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkLowMemory() async {
    final isLowRam = await _deviceCapabilities.isLowRamDevice();
    if (!mounted) return;
    setState(() {
      _lowMemoryDevice = isLowRam;
      _checkedLowMemory = true;
    });
    if (isLowRam) {
      final settings = context.read<SettingsController>();
      if (!settings.settings.lowMemoryWarningSeen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.lowMemoryModeEnabled)),
          );
          settings.markLowMemoryWarningSeen();
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializingCamera) return;
    _initializingCamera = true;
    try {
      _cameras = await availableCameras();
      if (!mounted || !widget.isActive || _cameras.isEmpty) return;
      _cameraController?.dispose();
      _cameraController = CameraController(
        _cameras[_selectedCamera],
        ResolutionPreset.medium, // Use medium for live + better performance
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      _cameraInit = _cameraController!.initialize();
      _cameraInit?.ignore();
      if (mounted) setState(() {});
    } catch (_) {
      // Camera init failures will fall back to placeholder UI.
    } finally {
      _initializingCamera = false;
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _stopLiveDetection();
    _selectedCamera = (_selectedCamera + 1) % _cameras.length;
    await _initializeCamera();
    if (_isLiveMode) {
      // Restart live detection on new camera after init
      _cameraInit?.then((_) {
        if (mounted && _isLiveMode) _startLiveDetection();
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(imageFile: File(file.path)),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null) return;
    try {
      await _cameraInit;
      // Pause live detection while capturing
      final wasLive = _isLiveMode;
      if (wasLive) _stopLiveDetection();

      await HapticFeedback.mediumImpact();
      final file = await controller.takePicture();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultsScreen(
            imageFile: File(file.path),
            autoStartProcessing: true,
            showRetakeAction: true,
          ),
        ),
      );

      // Resume live detection on return
      if (wasLive && mounted) _startLiveDetection();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.photoCaptureFailed)),
      );
    }
  }

  // ─── Live detection ────────────────────────────────────────────────

  void _toggleLiveMode() {
    setState(() => _isLiveMode = !_isLiveMode);
    if (_isLiveMode) {
      _startLiveDetection();
    } else {
      _stopLiveDetection();
    }
  }

  void _startLiveDetection() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    _frameCount = 0;
    _fpsTimestamp = DateTime.now();

    controller.startImageStream(_onCameraFrame);
  }

  void _stopLiveDetection() {
    final controller = _cameraController;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
    setState(() {
      _liveDetections = <DetectedObject>[];
      _fps = 0;
      _inferenceMs = 0;
    });
  }

  void _onCameraFrame(CameraImage cameraImage) {
    if (_isProcessingFrame || !mounted) return;
    _isProcessingFrame = true;
    _processFrame(cameraImage).then((_) {
      _isProcessingFrame = false;
    });
  }

  Future<void> _processFrame(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to img.Image
      final image = _convertCameraImage(cameraImage);
      if (image == null) return;

      final sc = context.read<SettingsController>();
      final ds = context.read<DetectionService>();
      final settings = sc.settings;

      final detections = await ds.detectFromImage(
        image: image,
        profile: settings.resolutionProfile,
        confidence: settings.confidenceThreshold,
        iou: settings.iouThreshold,
        useNms: settings.useNms,
        maxDetections: settings.maxDetections,
        selectedLabels: sc.selectedLabels,
        filterBySelectedLabels: !settings.useCustomModel,
      );

      // Update FPS counter
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_fpsTimestamp).inMilliseconds;
      if (elapsed >= 1000) {
        _fps = _frameCount * 1000.0 / elapsed;
        _frameCount = 0;
        _fpsTimestamp = now;
      }

      if (!mounted) return;
      setState(() {
        _liveDetections = detections;
        _inferenceMs = ds.lastInferenceMs;
      });
    } catch (e) {
      debugPrint('Live detection error: $e');
    }
  }

  /// Convert a [CameraImage] to an [img.Image].
  ///
  /// Supports YUV420 (Android) and BGRA8888 (iOS).
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYuv420(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBgra8888(cameraImage);
      }
    } catch (e) {
      debugPrint('Image conversion error: $e');
    }
    return null;
  }

  img.Image _convertYuv420(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final result = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

        final yVal = yPlane.bytes[yIndex];
        final uVal = uPlane.bytes[uvIndex];
        final vVal = vPlane.bytes[uvIndex];

        final r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();

        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return result;
  }

  img.Image _convertBgra8888(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final bytes = image.planes[0].bytes;
    final bytesPerRow = image.planes[0].bytesPerRow;

    final result = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * bytesPerRow + x * 4;
        result.setPixelRgba(x, y, bytes[i + 2], bytes[i + 1], bytes[i], 255);
      }
    }

    return result;
  }

  @override
  void dispose() {
    _stopLiveDetection();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: <Widget>[
                        // Camera preview
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _cameraController == null
                                ? const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 64,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : FutureBuilder<void>(
                                    future: _cameraInit,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                const Icon(
                                                  Icons.videocam_off_outlined,
                                                  size: 48,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  l10n.cameraInitFailed,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return CameraPreview(
                                            _cameraController!);
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        // Live detection bounding box overlay
                        if (_isLiveMode && _liveDetections.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BoundingBoxOverlay(
                                detections: _liveDetections,
                                imageWidth:
                                    _cameraController?.value.previewSize
                                            ?.height
                                            .toInt() ??
                                        1,
                                imageHeight:
                                    _cameraController?.value.previewSize?.width
                                            .toInt() ??
                                        1,
                              ),
                            ),
                          ),

                        // Back button
                        Positioned(
                          top: 20,
                          left: 20,
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).maybePop();
                            },
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),

                        // Settings button
                        Positioned(
                          top: 20,
                          right: 20,
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings),
                          ),
                        ),

                        // Detection info badge
                        Positioned(
                          top: 72,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Consumer<SettingsController>(
                              builder: (context, sc, _) {
                                final labels = sc.selectedLabels.toList();
                                final String badgeText;
                                if (labels.isEmpty) {
                                  badgeText = l10n.noClassesSelected;
                                } else if (labels.length <= 3) {
                                  badgeText = l10n.detectingLabels(
                                    labels
                                        .map((l) => l.toUpperCase())
                                        .join(', '),
                                  );
                                } else {
                                  final first = labels
                                      .take(3)
                                      .map((l) => l.toUpperCase())
                                      .join(', ');
                                  badgeText = l10n.detectingLabelsMore(
                                    first,
                                    labels.length - 3,
                                  );
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Detection frame guide (only in capture mode)
                        if (!_isLiveMode)
                          Positioned(
                            left: 40,
                            right: 40,
                            top: 140,
                            bottom: 180,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.primary, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),

                        // FPS counter (live mode)
                        if (_isLiveMode)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: FpsCounter(
                              fps: _fps,
                              inferenceMs: _inferenceMs,
                            ),
                          ),

                        // Live detection count chip
                        if (_isLiveMode && _liveDetections.isNotEmpty)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.objectsDetected(
                                    _liveDetections.length),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        // Low memory warning
                        if (_checkedLowMemory &&
                            _lowMemoryDevice &&
                            !_isLiveMode)
                          Positioned(
                            bottom: 24,
                            left: 24,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.warning),
                              ),
                              child: Text(
                                l10n.lowMemoryMode,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Bottom controls ───────────────────────────────────

                // Live / Capture mode toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLiveMode ? _toggleLiveMode : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLiveMode
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.photo_camera,
                                      size: 16,
                                      color: !_isLiveMode
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.captureMode,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: !_isLiveMode
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: !_isLiveMode ? _toggleLiveMode : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLiveMode
                                    ? AppColors.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: 16,
                                      color: _isLiveMode
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.liveMode,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _isLiveMode
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      onPressed: _pickFromGallery,
                      tooltip: l10n.pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                    Semantics(
                      label: l10n.navCapture,
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _capturePhoto,
                          customBorder: const CircleBorder(),
                          splashColor:
                              AppColors.primary.withValues(alpha: 0.3),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isLiveMode
                                      ? AppColors.accent
                                      : AppColors.primary,
                                ),
                                child: _isLiveMode
                                    ? const Icon(Icons.photo_camera,
                                        color: Colors.white, size: 28)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          onPressed: _flipCamera,
                          tooltip: l10n.flipCamera,
                          icon: const Icon(Icons.cameraswitch),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PreferencesScreen(),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Consumer<SettingsController>(
                                builder: (context, sc, __) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      l10n.classCount(
                                          sc.selectedLabels.length),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right,
                                        size: 14, color: AppColors.accent),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
