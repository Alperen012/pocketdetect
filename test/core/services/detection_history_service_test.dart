import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/models/detected_object.dart';
import 'package:mobile_yolo/core/models/detection_history_entry.dart';
import 'package:mobile_yolo/core/services/detection_history_service.dart';

DetectionHistoryEntry _makeEntry(String id) {
  return DetectionHistoryEntry(
    id: id,
    imagePath: '/tmp/$id.jpg',
    detections: const [
      DetectedObject(
        label: 'person',
        confidence: 0.9,
        boundingBox: Rect.fromLTWH(0, 0, 100, 200),
      ),
    ],
    timestamp: DateTime.utc(2026, 3, 11),
    inferenceMs: 30,
    modelName: 'YOLOv8n',
  );
}

void main() {
  group('DetectionHistoryService', () {
    late SharedPreferences prefs;
    late DetectionHistoryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = DetectionHistoryService(prefs);
    });

    test('starts empty', () {
      expect(service.entries, isEmpty);
      expect(service.count, 0);
      expect(service.isEmpty, true);
    });

    test('addEntry() inserts at position 0 (newest first)', () async {
      await service.addEntry(_makeEntry('a'));
      await service.addEntry(_makeEntry('b'));

      expect(service.entries[0].id, 'b');
      expect(service.entries[1].id, 'a');
      expect(service.count, 2);
    });

    test('addEntry() caps at 50 entries', () async {
      for (var i = 0; i < 55; i++) {
        await service.addEntry(_makeEntry('entry-$i'));
      }

      expect(service.count, 50);
      // Newest entry should be first
      expect(service.entries[0].id, 'entry-54');
    });

    test('removeEntry() removes by ID', () async {
      await service.addEntry(_makeEntry('keep'));
      await service.addEntry(_makeEntry('remove'));

      await service.removeEntry('remove');

      expect(service.count, 1);
      expect(service.entries[0].id, 'keep');
    });

    test('removeEntry() no-op for unknown ID', () async {
      await service.addEntry(_makeEntry('a'));
      await service.removeEntry('nonexistent');
      expect(service.count, 1);
    });

    test('clearAll() empties the list', () async {
      await service.addEntry(_makeEntry('a'));
      await service.addEntry(_makeEntry('b'));
      await service.clearAll();

      expect(service.entries, isEmpty);
      expect(service.isEmpty, true);
    });

    test('entries survive reconstruction (persistence)', () async {
      await service.addEntry(_makeEntry('persistent'));

      // Reconstruct from same prefs
      final service2 = DetectionHistoryService(prefs);

      expect(service2.count, 1);
      expect(service2.entries[0].id, 'persistent');
      expect(service2.entries[0].modelName, 'YOLOv8n');
    });

    test('notifyListeners fires on addEntry', () async {
      var notified = false;
      service.addListener(() => notified = true);
      await service.addEntry(_makeEntry('x'));
      expect(notified, true);
    });

    test('notifyListeners fires on removeEntry', () async {
      await service.addEntry(_makeEntry('x'));
      var notified = false;
      service.addListener(() => notified = true);
      await service.removeEntry('x');
      expect(notified, true);
    });

    test('notifyListeners fires on clearAll', () async {
      await service.addEntry(_makeEntry('x'));
      var notified = false;
      service.addListener(() => notified = true);
      await service.clearAll();
      expect(notified, true);
    });

    test('entries list is unmodifiable', () {
      expect(() => service.entries.add(_makeEntry('x')), throwsA(anything));
    });
  });
}
