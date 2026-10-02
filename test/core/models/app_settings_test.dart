import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/models/app_settings.dart';
import 'package:mobile_yolo/core/models/resolution_profile.dart';

void main() {
  group('AppSettings', () {
    test('defaults has expected values', () {
      const s = AppSettings.defaults;

      expect(s.resolutionProfile, ResolutionProfile.quality);
      expect(s.confidenceThreshold, 0.5);
      expect(s.iouThreshold, 0.45);
      expect(s.useNms, true);
      expect(s.maxDetections, 100);
      expect(s.lowMemoryWarningSeen, false);
    });

    test('copyWith() with no args returns identical settings', () {
      const original = AppSettings.defaults;
      final copy = original.copyWith();

      expect(copy.resolutionProfile, original.resolutionProfile);
      expect(copy.confidenceThreshold, original.confidenceThreshold);
      expect(copy.iouThreshold, original.iouThreshold);
      expect(copy.useNms, original.useNms);
      expect(copy.maxDetections, original.maxDetections);
      expect(copy.lowMemoryWarningSeen, original.lowMemoryWarningSeen);
    });

    test('copyWith() with changed value returns updated settings', () {
      const original = AppSettings.defaults;
      final updated = original.copyWith(
        confidenceThreshold: 0.8,
        iouThreshold: 0.3,
        useNms: false,
        maxDetections: 50,
      );

      expect(updated.confidenceThreshold, 0.8);
      expect(updated.iouThreshold, 0.3);
      expect(updated.useNms, false);
      expect(updated.maxDetections, 50);
      // Unchanged fields stay the same
      expect(updated.resolutionProfile, original.resolutionProfile);
      expect(updated.lowMemoryWarningSeen, original.lowMemoryWarningSeen);
    });
  });
}
