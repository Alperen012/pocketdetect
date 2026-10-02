import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/detected_object.dart';
import '../../core/models/detection_history_entry.dart';
import '../../core/services/detection_history_service.dart';
import '../../core/services/detection_service.dart';
import '../../core/services/model_library_service.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.imageFile,
    this.autoStartProcessing = true,
    this.showRetakeAction = false,
  });

  final File imageFile;
  final bool autoStartProcessing;
  final bool showRetakeAction;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Future<List<DetectedObject>>? _future;
  bool _isAnalyzing = false;
  bool _isActionInProgress = false;
  bool _showOverlay = true;
  double _imageAspectRatio = 1.0;

  bool get _hasAnalysisStarted => _future != null;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
    if (widget.autoStartProcessing) {
      _startDetection();
    }
  }

  void _loadImageDimensions() {
    final imageProvider = FileImage(widget.imageFile);
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _imageAspectRatio = info.image.width / info.image.height;
        });
      }
    }));
  }

  Future<void> _startDetection() async {
    if (_isAnalyzing || _future != null) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }

    final detectionService = context.read<DetectionService>();
    final settings = context.read<SettingsController>();
    final model = context.read<ModelLibraryService>().activeModel;

    await detectionService.reloadIfNeeded(model);

    if (detectionService.error != null) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
      return;
    }

    final future = detectionService.detectObjects(
      imageFile: widget.imageFile,
      profile: settings.settings.resolutionProfile,
      confidence: settings.settings.confidenceThreshold,
      iou: settings.settings.iouThreshold,
      useNms: settings.settings.useNms,
      maxDetections: settings.settings.maxDetections,
      selectedLabels: settings.selectedLabels,
      filterBySelectedLabels: model.supportsLabelFilter,
    );

    setState(() {
      _future = future;
    });

    future.whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAnalyzing = false;
      });
    });

    // Save to history when detection completes
    future.then((detections) {
      if (!mounted || detections.isEmpty) return;
      final historyService = context.read<DetectionHistoryService>();
      final modelName = model.name;
      historyService.addEntry(DetectionHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: widget.imageFile.path,
        detections: detections,
        timestamp: DateTime.now(),
        inferenceMs: detectionService.lastInferenceMs,
        modelName: modelName,
      ));
    }).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final detectionService = context.watch<DetectionService>();
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detectionResults),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(widget.imageFile, fit: BoxFit.contain),
                      ),
                    ),
                    if (_future != null)
                      Positioned.fill(
                        child: FutureBuilder<List<DetectedObject>>(
                          future: _future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildImageLoadingOverlay();
                            }
                            if (snapshot.hasError || !_showOverlay) {
                              return const SizedBox.shrink();
                            }
                            final detections = snapshot.data ?? <DetectedObject>[];
                            if (detections.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return CustomPaint(
                              painter: _DetectionPainter(
                                detections,
                                imageAspectRatio: _imageAspectRatio,
                              ),
                            );
                          },
                        ),
                      ),
                    // Overlay toggle — only shown after processing finishes
                    if (!_isAnalyzing && _hasAnalysisStarted)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => setState(() => _showOverlay = !_showOverlay),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                _showOverlay
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Inference-time badge — only shown after processing finishes
                    if (!_isAnalyzing && _hasAnalysisStarted)
                      Positioned(
                        bottom: 10,
                        right: 12,
                        child: FutureBuilder<List<DetectedObject>>(
                          future: _future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const SizedBox.shrink();
                            }
                            final ms = detectionService.lastInferenceMs;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.speed_outlined,
                                      size: 12, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.inferenceTimeMs(ms),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(l10n.analysisSummary,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Chip(label: Text(l10n.results)),
              ],
            ),
            const SizedBox(height: 12),
            if (detectionService.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade700),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        detectionService.error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else if (_future == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  l10n.photoReadyTapToProcess,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              FutureBuilder<List<DetectedObject>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryLoadingState();
                  }
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade700),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.analysisError(snapshot.error.toString()),
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final detections = snapshot.data ?? <DetectedObject>[];
                  if (detections.isEmpty) {
                    return Text(
                      l10n.noDetectionsFound,
                      style: const TextStyle(color: AppColors.textSecondary),
                    );
                  }
                  final summary = _summarize(detections);
                  return Column(
                    children: summary
                        .map(
                          (item) => Card(
                            child: ListTile(
                              title: Text(item.label),
                              subtitle: Text(
                                l10n.confidenceValue(item.maxConfidence.toStringAsFixed(2)),
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              trailing: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(l10n.itemCount(item.count)),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            const SizedBox(height: 20),
            if (!_hasAnalysisStarted) ...<Widget>[
              Row(
                children: <Widget>[
                  if (widget.showRetakeAction) ...<Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isAnalyzing
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(l10n.retake),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _startDetection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(_isAnalyzing ? l10n.starting : l10n.startProcessing),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing ||
                            _isActionInProgress ||
                            !_hasAnalysisStarted
                        ? null
                        : _saveResult,
                    icon: _isActionInProgress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isActionInProgress ? l10n.processing : l10n.save),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isAnalyzing ||
                            _isActionInProgress ||
                            !_hasAnalysisStarted
                        ? null
                        : _shareResult,
                    icon: _isActionInProgress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share),
                    label: Text(_isActionInProgress ? l10n.processing : l10n.shareResult),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<DetectedObject>> _resolveDetections() async {
    final future = _future;
    if (future == null) {
      return <DetectedObject>[];
    }
    return future;
  }

  Future<void> _saveResult() async {
    final l10n = context.l10n;
    if (_isAnalyzing) {
      _showInfo(l10n.analysisInProgressWait);
      return;
    }
    if (_isActionInProgress) {
      return;
    }

    setState(() {
      _isActionInProgress = true;
    });

    List<DetectedObject> detections;
    try {
      detections = await _resolveDetections();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }

    final report = _buildReportText(detections);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/yolo_detection_$timestamp.txt');
      await file.writeAsString(report, flush: true);
      if (!mounted) {
        return;
      }
      _showInfo(l10n.reportSaved);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showInfo(l10n.reportSaveFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      }
    }
  }

  Future<void> _shareResult() async {
    final l10n = context.l10n;
    if (_isAnalyzing) {
      _showInfo(l10n.analysisInProgressWait);
      return;
    }
    if (_isActionInProgress) {
      return;
    }

    setState(() {
      _isActionInProgress = true;
    });

    List<DetectedObject> detections;
    try {
      detections = await _resolveDetections();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }

    final shareText = _buildReportText(detections);
    try {
      if (await widget.imageFile.exists()) {
        await Share.shareXFiles(
          <XFile>[XFile(widget.imageFile.path)],
          text: shareText,
          subject: l10n.shareSubject,
        );
      } else {
        await Share.share(
          shareText,
          subject: l10n.shareSubject,
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (!mounted) {
        return;
      }
      _showInfo(l10n.shareFailedCopied);
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      }
    }
  }

  Widget _buildImageLoadingOverlay() {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.20),
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              l10n.analyzingImage,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.modelRunningOnDevice,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryLoadingState() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LinearProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            l10n.analysisInProgress,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.analysisSteps,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildReportText(List<DetectedObject> detections) {
    final l10n = context.l10n;
    final summary = _summarize(detections);
    final buffer = StringBuffer();
    buffer.writeln(l10n.reportTitle);
    buffer.writeln(l10n.reportGenerated(DateTime.now().toIso8601String()));
    buffer.writeln(l10n.reportImage(widget.imageFile.path));
    buffer.writeln(l10n.reportTotalDetections(detections.length));
    buffer.writeln('');

    if (summary.isEmpty) {
      buffer.writeln(l10n.noDetectionsFound);
      return buffer.toString();
    }

    buffer.writeln(l10n.reportSummaryHeader);
    for (final item in summary) {
      buffer.writeln(
        '- ${item.label}: ${item.count} (max confidence: ${item.maxConfidence.toStringAsFixed(2)})',
      );
    }

    buffer.writeln('');
    buffer.writeln(l10n.reportDetailedHeader);
    for (var i = 0; i < detections.length; i++) {
      final d = detections[i];
      final bbox = d.boundingBox;
      buffer.writeln(
        '${i + 1}. ${d.label} — ${(d.confidence * 100).toStringAsFixed(1)}%',
      );
      buffer.writeln(
        l10n.reportBoundingBox(
          bbox.left.toStringAsFixed(4),
          bbox.top.toStringAsFixed(4),
          bbox.width.toStringAsFixed(4),
          bbox.height.toStringAsFixed(4),
        ),
      );
    }
    return buffer.toString();
  }

  List<_SummaryItem> _summarize(List<DetectedObject> detections) {
    final Map<String, _SummaryItem> map = <String, _SummaryItem>{};
    for (final detection in detections) {
      final existing = map[detection.label];
      if (existing == null) {
        map[detection.label] = _SummaryItem(
          label: detection.label,
          count: 1,
          maxConfidence: detection.confidence,
        );
      } else {
        map[detection.label] = _SummaryItem(
          label: detection.label,
          count: existing.count + 1,
          maxConfidence: detection.confidence > existing.maxConfidence
              ? detection.confidence
              : existing.maxConfidence,
        );
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.maxConfidence.compareTo(a.maxConfidence));
    return list;
  }
}

@immutable
class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.count,
    required this.maxConfidence,
  });

  final String label;
  final int count;
  final double maxConfidence;
}

class _DetectionPainter extends CustomPainter {
  const _DetectionPainter(this.detections, {this.imageAspectRatio = 1.0});

  final List<DetectedObject> detections;
  final double imageAspectRatio;

  static const List<Color> _palette = <Color>[
    Color(0xFF1B63FF),
    Color(0xFF22D3EE),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFFA855F7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Compute the fitted image rect (matching BoxFit.contain behaviour)
    // so that painted boxes align with the actual rendered image.
    final containerAR = size.width / size.height;
    final Size imageSize;
    final Offset imageOffset;
    if (imageAspectRatio > containerAR) {
      // Image is wider than container — fits width, letterbox top/bottom.
      imageSize = Size(size.width, size.width / imageAspectRatio);
      imageOffset = Offset(0, (size.height - imageSize.height) / 2);
    } else {
      // Image is taller or equal — fits height, letterbox left/right.
      imageSize = Size(size.height * imageAspectRatio, size.height);
      imageOffset = Offset((size.width - imageSize.width) / 2, 0);
    }

    for (var i = 0; i < detections.length; i++) {
      final detection = detections[i];
      final color = _palette[i % _palette.length];

      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final rect = Rect.fromLTWH(
        imageOffset.dx + detection.boundingBox.left * imageSize.width,
        imageOffset.dy + detection.boundingBox.top * imageSize.height,
        detection.boundingBox.width * imageSize.width,
        detection.boundingBox.height * imageSize.height,
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)), boxPaint);

      // Label badge
      final labelText =
          '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(
        text: labelText,
        style: TextStyle(
          color: Colors.white,
          fontSize: imageSize.width * 0.032,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: imageSize.width);

      const padding = 4.0;
      final badgeWidth = textPainter.width + padding * 2;
      final badgeHeight = textPainter.height + padding * 2;
      final badgeTop =
          rect.top > badgeHeight ? rect.top - badgeHeight : rect.top;
      final badgeRect = Rect.fromLTWH(rect.left, badgeTop, badgeWidth, badgeHeight);

      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = color,
      );
      textPainter.paint(
          canvas, Offset(badgeRect.left + padding, badgeRect.top + padding));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return !listEquals(oldDelegate.detections, detections) ||
        oldDelegate.imageAspectRatio != imageAspectRatio;
  }
}

