import 'package:flutter/material.dart';

import '../../../core/models/detected_object.dart';
import '../../../core/theme/app_colors.dart';

/// Paints bounding boxes and labels on top of the camera preview.
///
/// [detections] are in normalised coordinates (0-1) relative to the
/// original image.  The painter maps them to the widget's actual size.
class BoundingBoxPainter extends CustomPainter {
  BoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  final List<DetectedObject> detections;
  final int imageWidth;
  final int imageHeight;

  static const _colors = <Color>[
    Color(0xFF00BCD4),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF2196F3),
    Color(0xFFFFEB3B),
    Color(0xFFE91E63),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (var i = 0; i < detections.length; i++) {
      final det = detections[i];
      final color = _colors[i % _colors.length];

      final rect = Rect.fromLTWH(
        det.boundingBox.left * scaleX,
        det.boundingBox.top * scaleY,
        det.boundingBox.width * scaleX,
        det.boundingBox.height * scaleY,
      );

      // Box
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        boxPaint,
      );

      // Label background
      final label = '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left,
          rect.top - textPainter.height - 6,
          textPainter.width + 10,
          textPainter.height + 6,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(bgRect, Paint()..color = color);
      textPainter.paint(
        canvas,
        Offset(rect.left + 5, rect.top - textPainter.height - 3),
      );
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return !identical(oldDelegate.detections, detections);
  }
}

/// A widget that overlays bounding boxes on the camera preview.
class BoundingBoxOverlay extends StatelessWidget {
  const BoundingBoxOverlay({
    super.key,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  final List<DetectedObject> detections;
  final int imageWidth;
  final int imageHeight;

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: BoundingBoxPainter(
        detections: detections,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// An FPS counter chip shown during live detection.
class FpsCounter extends StatelessWidget {
  const FpsCounter({
    super.key,
    required this.fps,
    required this.inferenceMs,
  });

  final double fps;
  final int inferenceMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            '${fps.toStringAsFixed(1)} FPS · ${inferenceMs}ms',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
