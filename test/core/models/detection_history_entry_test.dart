import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/models/detected_object.dart';
import 'package:mobile_yolo/core/models/detection_history_entry.dart';

void main() {
  DetectionHistoryEntry makeEntry({
    String id = 'test-1',
    String imagePath = '/tmp/test.jpg',
    int inferenceMs = 42,
    String modelName = 'YOLOv8n',
    DateTime? timestamp,
    List<DetectedObject>? detections,
  }) {
    return DetectionHistoryEntry(
      id: id,
      imagePath: imagePath,
      detections: detections ??
          [
            const DetectedObject(
              label: 'cat',
              confidence: 0.95,
              boundingBox: Rect.fromLTWH(10, 20, 100, 200),
            ),
            const DetectedObject(
              label: 'dog',
              confidence: 0.80,
              boundingBox: Rect.fromLTWH(50, 60, 150, 250),
            ),
          ],
      timestamp: timestamp ?? DateTime.utc(2026, 3, 11, 12, 0, 0),
      inferenceMs: inferenceMs,
      modelName: modelName,
    );
  }

  group('DetectionHistoryEntry', () {
    test('toJson() produces expected map', () {
      final entry = makeEntry();
      final json = entry.toJson();

      expect(json['id'], 'test-1');
      expect(json['imagePath'], '/tmp/test.jpg');
      expect(json['inferenceMs'], 42);
      expect(json['modelName'], 'YOLOv8n');
      expect(json['timestamp'], '2026-03-11T12:00:00.000Z');
      expect(json['detections'], isList);
      expect((json['detections'] as List).length, 2);
    });

    test('fromJson() round-trips correctly', () {
      final original = makeEntry();
      final restored = DetectionHistoryEntry.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.imagePath, original.imagePath);
      expect(restored.inferenceMs, original.inferenceMs);
      expect(restored.modelName, original.modelName);
      expect(restored.timestamp, original.timestamp);
      expect(restored.detections.length, original.detections.length);
      expect(restored.detections[0].label, 'cat');
      expect(restored.detections[0].confidence, 0.95);
      expect(restored.detections[1].label, 'dog');
    });

    test('encodeList / decodeList round-trips a list', () {
      final entries = [
        makeEntry(id: 'a'),
        makeEntry(id: 'b', inferenceMs: 99),
      ];
      final encoded = DetectionHistoryEntry.encodeList(entries);
      final decoded = DetectionHistoryEntry.decodeList(encoded);

      expect(decoded.length, 2);
      expect(decoded[0].id, 'a');
      expect(decoded[1].id, 'b');
      expect(decoded[1].inferenceMs, 99);
    });

    test('handles zero detections', () {
      final entry = makeEntry(detections: []);
      final restored = DetectionHistoryEntry.fromJson(entry.toJson());

      expect(restored.detections, isEmpty);
      expect(restored.objectCount, 0);
    });

    test('objectCount returns detection list length', () {
      final entry = makeEntry();
      expect(entry.objectCount, 2);
    });
  });
}
