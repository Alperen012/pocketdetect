import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/detected_object.dart';
import '../../core/models/detection_history_entry.dart';
import '../../core/services/detection_history_service.dart';
import '../../core/services/detection_service.dart';
import '../../core/services/model_library_service.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';

/// Allows the user to pick multiple images and run detection on each.
class BatchDetectionScreen extends StatefulWidget {
  const BatchDetectionScreen({super.key});

  @override
  State<BatchDetectionScreen> createState() => _BatchDetectionScreenState();
}

class _BatchDetectionScreenState extends State<BatchDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  bool _isProcessing = false;
  int _currentIndex = 0;
  List<_BatchResult> _results = [];

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images = picked.map((x) => File(x.path)).toList();
        _results = [];
      });
    }
  }

  Future<void> _runBatchDetection() async {
    if (_images.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _currentIndex = 0;
      _results = [];
    });

    final ds = context.read<DetectionService>();
    final sc = context.read<SettingsController>();
    final historyService = context.read<DetectionHistoryService>();
    final settings = sc.settings;
    final model = context.read<ModelLibraryService>().activeModel;

    await ds.reloadIfNeeded(model);

    for (var i = 0; i < _images.length; i++) {
      if (!mounted) return;
      setState(() => _currentIndex = i);

      try {
        final detections = await ds.detectObjects(
          imageFile: _images[i],
          profile: settings.resolutionProfile,
          confidence: settings.confidenceThreshold,
          iou: settings.iouThreshold,
          useNms: settings.useNms,
          maxDetections: settings.maxDetections,
          selectedLabels: sc.selectedLabels,
          filterBySelectedLabels: model.supportsLabelFilter,
        );

        _results.add(_BatchResult(
          file: _images[i],
          detections: detections,
          inferenceMs: ds.lastInferenceMs,
        ));

        // Save to history
        if (detections.isNotEmpty) {
          historyService.addEntry(DetectionHistoryEntry(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            imagePath: _images[i].path,
            detections: detections,
            timestamp: DateTime.now(),
            inferenceMs: ds.lastInferenceMs,
            modelName: model.name,
          ));
        }
      } catch (e) {
        _results.add(_BatchResult(
          file: _images[i],
          detections: [],
          inferenceMs: 0,
          error: e.toString(),
        ));
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  int get _totalObjects =>
      _results.fold<int>(0, (sum, r) => sum + r.detections.length);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.batchTitle)),
      body: Column(
        children: [
          // Select Images button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.batchSelectImages),
              ),
            ),
          ),

          // Image grid or empty state
          Expanded(
            child: _images.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.collections_outlined,
                              size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            l10n.batchNoImages,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.batchNoImagesHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildContent(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic l10n) {
    return Column(
      children: [
        // Processing bar
        if (_isProcessing) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _images.length,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.batchProcessing(
                    _currentIndex + 1,
                    _images.length,
                  ),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Summary after processing
        if (!_isProcessing && _results.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B63FF), Color(0xFF22D3EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.batchComplete,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.batchSummary(_results.length, _totalObjects),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Image grid with results overlay
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final hasResult = index < _results.length;
              final result = hasResult ? _results[index] : null;

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_images[index], fit: BoxFit.cover),
                    // Processing indicator
                    if (_isProcessing && index == _currentIndex)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    // Result badge
                    if (hasResult && result != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: result.detections.isNotEmpty
                                ? AppColors.accent
                                : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${result.detections.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Run button
        if (_images.isNotEmpty && !_isProcessing && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _runBatchDetection,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.batchStartProcessing),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BatchResult {
  const _BatchResult({
    required this.file,
    required this.detections,
    required this.inferenceMs,
    this.error,
  });

  final File file;
  final List<DetectedObject> detections;
  final int inferenceMs;
  final String? error;
}
