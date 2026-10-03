import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/detection/camera_errors.dart';
import '../../core/detection/camera_frame.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/detected_object.dart';
import '../../core/services/detection_service.dart';
import '../../core/services/device_capabilities.dart';
import '../../core/services/model_library_service.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
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
  double _zoom = 1;
  double _zoomBase = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
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
      _zoom = 1;
      _minZoom = 1;
      _maxZoom = 1;
      final controller = _cameraController!;
      _cameraInit = controller.initialize().then((_) async {
        _minZoom = await controller.getMinZoomLevel();
        _maxZoom = await controller.getMaxZoomLevel();
      });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.photoCaptureFailed)));
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

  /// Stops the camera image stream and clears the live overlay. Pass
  /// `updateUi: false` from [dispose], where calling `setState` is an error.
  void _stopLiveDetection({bool updateUi = true}) {
    final controller = _cameraController;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
    if (!updateUi) return;
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
      final frame = _frameDataFrom(cameraImage);
      if (frame == null) return;

      final sc = context.read<SettingsController>();
      final ds = context.read<DetectionService>();
      final settings = sc.settings;
      final model = context.read<ModelLibraryService>().activeModel;

      // Convert + rotate upright off the UI thread.
      final image = await compute(convertCameraFrame, frame);

      final detections = await ds.detectFromImage(
        image: image,
        profile: settings.resolutionProfile,
        confidence: settings.confidenceThreshold,
        iou: settings.iouThreshold,
        useNms: settings.useNms,
        maxDetections: settings.maxDetections,
        selectedLabels: sc.selectedLabels,
        filterBySelectedLabels: model.supportsLabelFilter,
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

  /// Packs a [CameraImage] for [convertCameraFrame], including the rotation
  /// that makes it upright for the current sensor and device orientation.
  CameraFrameData? _frameDataFrom(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final rotation = frameRotationDegrees(
      sensorOrientation: controller.description.sensorOrientation,
      deviceOrientationDegrees: _deviceOrientationDegrees(controller),
      isFrontCamera:
          controller.description.lensDirection == CameraLensDirection.front,
    );

    switch (image.format.group) {
      case ImageFormatGroup.yuv420:
        if (image.planes.length < 3) return null;
        return CameraFrameData(
          format: CameraFrameFormat.yuv420,
          width: image.width,
          height: image.height,
          plane0: image.planes[0].bytes,
          rowStride0: image.planes[0].bytesPerRow,
          plane1: image.planes[1].bytes,
          plane2: image.planes[2].bytes,
          uvRowStride: image.planes[1].bytesPerRow,
          uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
          rotationDegrees: rotation,
        );
      case ImageFormatGroup.bgra8888:
        return CameraFrameData(
          format: CameraFrameFormat.bgra8888,
          width: image.width,
          height: image.height,
          plane0: image.planes[0].bytes,
          rowStride0: image.planes[0].bytesPerRow,
          rotationDegrees: rotation,
        );
      default:
        return null;
    }
  }

  int _deviceOrientationDegrees(CameraController controller) {
    return switch (controller.value.deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
  }

  /// Shown when the camera could not start. A denied permission gets its own
  /// message and a way forward (the gallery), since retrying cannot help.
  Widget _buildCameraError(Object? error) {
    final l10n = context.l10n;
    final denied = isCameraPermissionError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.videocam_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              denied ? l10n.cameraPermissionDenied : l10n.cameraInitFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (denied) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.pickFromGallery),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Camera preview scaled to cover the available area without distortion,
  /// with the detection overlay drawn in the same coordinate space so boxes
  /// line up with what is visible.
  Widget _buildPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    final overlay = _isLiveMode && _liveDetections.isNotEmpty
        ? BoundingBoxOverlay(detections: _liveDetections)
        : null;
    if (previewSize == null) {
      return CameraPreview(controller, child: overlay);
    }

    // previewSize is reported in sensor (landscape) terms; flip it when the
    // device is held upright so the box matches what CameraPreview renders.
    final portrait = switch (controller.value.deviceOrientation) {
      DeviceOrientation.portraitUp || DeviceOrientation.portraitDown => true,
      _ => false,
    };
    final width = portrait ? previewSize.height : previewSize.width;
    final height = portrait ? previewSize.width : previewSize.height;

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: height,
        child: CameraPreview(controller, child: overlay),
      ),
    );
  }

  @override
  void dispose() {
    _stopLiveDetection(updateUi: false);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final card = _buildPreviewCard(l10n);
            final toggle = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildModeToggle(l10n),
            );
            if (orientation == Orientation.landscape) {
              // Preview on the left, a narrow control strip on the right.
              return Row(
                children: <Widget>[
                  Expanded(child: card),
                  SizedBox(
                    width: 250,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            toggle,
                            const SizedBox(height: 16),
                            _buildShutterButton(l10n),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                _buildGalleryButton(l10n),
                                _buildFlipButton(l10n),
                              ],
                            ),
                            _buildClassChip(l10n),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: <Widget>[
                Expanded(child: card),
                const SizedBox(height: 8),
                toggle,
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _buildGalleryButton(l10n),
                    _buildShutterButton(l10n),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildFlipButton(l10n),
                        _buildClassChip(l10n),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The camera preview card with its overlays.
  Widget _buildPreviewCard(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: <Widget>[
          // Camera preview
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) => _zoomBase = _zoom,
              onScaleUpdate: (d) => _setZoom(_zoomBase * d.scale),
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
                              return _buildCameraError(snapshot.error);
                            }
                            return _buildPreview(_cameraController!);
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
              ),
            ),
          ),

          // Zoom indicator
          if (_zoom > 1.05)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_zoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                      labels.map((l) => l.toUpperCase()).join(', '),
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
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
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
            // Purely visual: it must not swallow the pinch-zoom gestures.
            Positioned.fill(
              child: IgnorePointer(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.55,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

          // FPS counter (live mode)
          if (_isLiveMode)
            Positioned(
              bottom: 12,
              right: 12,
              child: FpsCounter(fps: _fps, inferenceMs: _inferenceMs),
            ),

          // Live detection count chip
          if (_isLiveMode && _liveDetections.isNotEmpty)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.objectsDetected(_liveDetections.length),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Low memory warning
          if (_checkedLowMemory && _lowMemoryDevice && !_isLiveMode)
            Positioned(
              bottom: 24,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Text(
                  l10n.lowMemoryMode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Photo / live mode switch.
  Widget _buildModeToggle(AppLocalizations l10n) {
    return Padding(
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
                    color: _isLiveMode ? AppColors.accent : Colors.transparent,
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
    );
  }

  Widget _buildGalleryButton(AppLocalizations l10n) {
    return IconButton(
      onPressed: _pickFromGallery,
      tooltip: l10n.pickFromGallery,
      icon: const Icon(Icons.photo_library_outlined),
    );
  }

  Widget _buildShutterButton(AppLocalizations l10n) {
    return Semantics(
      label: l10n.navCapture,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _capturePhoto,
          customBorder: const CircleBorder(),
          splashColor: AppColors.primary.withValues(alpha: 0.3),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isLiveMode ? AppColors.accent : AppColors.primary,
                ),
                child: _isLiveMode
                    ? const Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 28,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlipButton(AppLocalizations l10n) {
    return IconButton(
      onPressed: _flipCamera,
      tooltip: l10n.flipCamera,
      icon: const Icon(Icons.cameraswitch),
    );
  }

  Widget _buildClassChip(AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PreferencesScreen()),
        ),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  l10n.classCount(sc.selectedLabels.length),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Zooms the camera. Hardware zoom, so live frames and photos are both
  /// zoomed and detection boxes stay aligned with the preview.
  void _setZoom(double value) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final zoom = value.clamp(_minZoom, _maxZoom).toDouble();
    if (zoom == _zoom) return;
    setState(() => _zoom = zoom);
    controller.setZoomLevel(zoom).catchError((_) {});
  }
}
