import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/detected_object.dart';
import '../../core/models/installed_model.dart';
import '../../core/services/detection_service.dart';
import '../../core/services/model_library_service.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../capture/widgets/bounding_box_overlay.dart';

/// Outcome of running one model on the shared image.
class CompareSide {
  const CompareSide({
    required this.model,
    this.detections = const <DetectedObject>[],
    this.inferenceMs = 0,
    this.error,
  });

  final InstalledModel model;
  final List<DetectedObject> detections;
  final int inferenceMs;
  final String? error;
}

/// Runs [model] on [image]; injectable so the screen can be tested.
typedef CompareRunner =
    Future<CompareSide> Function({
      required InstalledModel model,
      required File image,
      required AppSettings settings,
      required Set<String> selectedLabels,
    });

/// Loads [model] into a throw-away [DetectionService], runs it once and frees
/// it, so comparing never disturbs the app's active model.
Future<CompareSide> _defaultRunner({
  required InstalledModel model,
  required File image,
  required AppSettings settings,
  required Set<String> selectedLabels,
}) async {
  final service = DetectionService();
  try {
    await service.initialize(model: model);
    final error = service.error;
    if (error != null) {
      return CompareSide(model: model, error: error);
    }
    final detections = await service.detectObjects(
      imageFile: image,
      profile: settings.resolutionProfile,
      confidence: settings.confidenceThreshold,
      iou: settings.iouThreshold,
      useNms: settings.useNms,
      maxDetections: settings.maxDetections,
      selectedLabels: selectedLabels,
      filterBySelectedLabels: model.supportsLabelFilter,
    );
    return CompareSide(
      model: model,
      detections: detections,
      inferenceMs: service.lastInferenceMs,
    );
  } catch (e) {
    return CompareSide(model: model, error: e.toString());
  } finally {
    service.dispose();
  }
}

Future<File?> _defaultPicker() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  return picked == null ? null : File(picked.path);
}

/// Runs two models on the same image, side by side.
class CompareScreen extends StatefulWidget {
  const CompareScreen({
    super.key,
    this.runner = _defaultRunner,
    this.pickImage = _defaultPicker,
  });

  final CompareRunner runner;
  final Future<File?> Function() pickImage;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String? _idA;
  String? _idB;
  File? _image;
  double _aspect = 1;
  bool _running = false;
  CompareSide? _resultA;
  CompareSide? _resultB;

  @override
  void initState() {
    super.initState();
    final library = context.read<ModelLibraryService>();
    final models = library.models;
    _idA = library.activeModel.id;
    _idB = models
        .firstWhere((m) => m.id != _idA, orElse: () => models.first)
        .id;
  }

  Future<void> _choose() async {
    final file = await widget.pickImage();
    if (file == null || !mounted) return;
    setState(() {
      _image = file;
      _aspect = 1; // square until the real size is known
      _resultA = null;
      _resultB = null;
    });
    _resolveAspect(file);
  }

  /// Learns the picture's proportions from the image stream, so the preview
  /// and the box overlay share one coordinate space.
  void _resolveAspect(File file) {
    final stream = FileImage(file).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      if (mounted && _image == file) {
        setState(() => _aspect = info.image.width / info.image.height);
      }
    }, onError: (_, __) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  Future<void> _run() async {
    final image = _image;
    if (image == null || _idA == null || _idB == null) return;
    final library = context.read<ModelLibraryService>();
    final settings = context.read<SettingsController>();
    final a = library.byId(_idA!);
    final b = library.byId(_idB!);
    if (a == null || b == null) return;

    setState(() {
      _running = true;
      _resultA = null;
      _resultB = null;
    });

    // One after the other: two interpreters at once would double peak memory.
    final resultA = await widget.runner(
      model: a,
      image: image,
      settings: settings.settings,
      selectedLabels: settings.selectedLabels,
    );
    if (!mounted) return;
    setState(() => _resultA = resultA);

    final resultB = await widget.runner(
      model: b,
      image: image,
      settings: settings.settings,
      selectedLabels: settings.selectedLabels,
    );
    if (!mounted) return;
    setState(() {
      _resultB = resultB;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final models = context.watch<ModelLibraryService>().models;
    final canRun = _image != null && !_running && _idA != _idB;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.compareTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            if (models.length < 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.compareNeedMore,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ModelPicker(
                    label: l10n.compareModelA,
                    value: _idA,
                    models: models,
                    onChanged: _running
                        ? null
                        : (v) => setState(() {
                            _idA = v;
                            _resultA = null;
                            _resultB = null;
                          }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModelPicker(
                    label: l10n.compareModelB,
                    value: _idB,
                    models: models,
                    onChanged: _running
                        ? null
                        : (v) => setState(() {
                            _idB = v;
                            _resultA = null;
                            _resultB = null;
                          }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _running ? null : _choose,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _image == null
                    ? l10n.compareChooseImage
                    : l10n.compareChangeImage,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: canRun ? _run : null,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.compare),
              label: Text(l10n.compareRun),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_image != null) ...<Widget>[
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _ResultPane(
                      image: _image!,
                      aspect: _aspect,
                      title: models.firstWhere((m) => m.id == _idA).name,
                      result: _resultA,
                      waiting: _running && _resultA == null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultPane(
                      image: _image!,
                      aspect: _aspect,
                      title: models.firstWhere((m) => m.id == _idB).name,
                      result: _resultB,
                      waiting: _running && _resultA != null && _resultB == null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModelPicker extends StatelessWidget {
  const _ModelPicker({
    required this.label,
    required this.value,
    required this.models,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<InstalledModel> models;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: <DropdownMenuItem<String>>[
        for (final m in models)
          DropdownMenuItem<String>(
            value: m.id,
            child: Text(m.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ResultPane extends StatelessWidget {
  const _ResultPane({
    required this.image,
    required this.aspect,
    required this.title,
    required this.result,
    required this.waiting,
  });

  final File image;
  final double aspect;
  final String title;
  final CompareSide? result;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = this.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: aspect,
            // Pinch to zoom; the boxes share the image's layer.
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(image, fit: BoxFit.fill),
                  if (result != null && result.error == null)
                    BoundingBoxOverlay(detections: result.detections),
                  if (waiting)
                    const ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (result != null)
          result.error != null
              ? Text(
                  l10n.compareFailed(title, result.error!),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                )
              : Text(
                  l10n.compareResult(
                    result.detections.length,
                    result.inferenceMs,
                  ),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
      ],
    );
  }
}
