import 'package:flutter/material.dart';

@immutable
class DetectedObject {
  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  final String label;
  final double confidence;
  final Rect boundingBox;
}
