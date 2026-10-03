import 'dart:convert';

import 'package:flutter/material.dart';

import 'detected_object.dart';

/// A single detection session record.
@immutable
class DetectionHistoryEntry {
  const DetectionHistoryEntry({
    required this.id,
    required this.imagePath,
    required this.detections,
    required this.timestamp,
    required this.inferenceMs,
    required this.modelName,
  });

  final String id;
  final String imagePath;
  final List<DetectedObject> detections;
  final DateTime timestamp;
  final int inferenceMs;
  final String modelName;

  int get objectCount => detections.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'detections': detections
        .map(
          (d) => {
            'label': d.label,
            'confidence': d.confidence,
            'left': d.boundingBox.left,
            'top': d.boundingBox.top,
            'width': d.boundingBox.width,
            'height': d.boundingBox.height,
          },
        )
        .toList(),
    'timestamp': timestamp.toIso8601String(),
    'inferenceMs': inferenceMs,
    'modelName': modelName,
  };

  factory DetectionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DetectionHistoryEntry(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      detections: (json['detections'] as List)
          .map(
            (d) => DetectedObject(
              label: d['label'] as String,
              confidence: (d['confidence'] as num).toDouble(),
              boundingBox: Rect.fromLTWH(
                (d['left'] as num).toDouble(),
                (d['top'] as num).toDouble(),
                (d['width'] as num).toDouble(),
                (d['height'] as num).toDouble(),
              ),
            ),
          )
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      inferenceMs: json['inferenceMs'] as int,
      modelName: json['modelName'] as String,
    );
  }

  /// Convenience: serialise the entire list to JSON string.
  static String encodeList(List<DetectionHistoryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  /// Convenience: deserialise a JSON string back to a list.
  static List<DetectionHistoryEntry> decodeList(String source) {
    final list = jsonDecode(source) as List;
    return list
        .map((e) => DetectionHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
