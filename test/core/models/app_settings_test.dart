import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/models/app_settings.dart';
import 'package:mobile_yolo/core/models/resolution_profile.dart';

void main() {
  group('AppSettings', () {
    test('defaults has expected values', () {
      const s = AppSettings.defaults;

      expect(s.modelId, 'yolo26_nano');
      expect(s.useCustomModel, false);
      expect(s.customModelPath, isNull);
      expect(s.customLabelsPath, isNull);
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

      expect(copy.modelId, original.modelId);
      expect(copy.confidenceThreshold, original.confidenceThreshold);
      expect(copy.iouThreshold, original.iouThreshold);
      expect(copy.useNms, original.useNms);
      expect(copy.maxDetections, original.maxDetections);
      expect(copy.useCustomModel, original.useCustomModel);
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
      expect(updated.modelId, original.modelId);
      expect(updated.useCustomModel, original.useCustomModel);
    });

    test('copyWith() clearCustomModelPath sets to null', () {
      final withPath = AppSettings.defaults.copyWith(
        customModelPath: '/some/model.tflite',
      );
      expect(withPath.customModelPath, '/some/model.tflite');

      final cleared = withPath.copyWith(clearCustomModelPath: true);
      expect(cleared.customModelPath, isNull);
    });

    test('copyWith() clearCustomLabelsPath sets to null', () {
      final withLabels = AppSettings.defaults.copyWith(
        customLabelsPath: '/some/labels.txt',
      );
      expect(withLabels.customLabelsPath, '/some/labels.txt');

      final cleared = withLabels.copyWith(clearCustomLabelsPath: true);
      expect(cleared.customLabelsPath, isNull);
    });

    test('copyWith() custom model metadata clear flags work', () {
      final withMeta = AppSettings.defaults.copyWith(
        customModelName: 'MyModel',
        customModelInputWidth: 640,
        customModelInputHeight: 640,
        customModelClassCount: 80,
        customModelQuantType: 'int8',
      );

      expect(withMeta.customModelName, 'MyModel');
      expect(withMeta.customModelInputWidth, 640);

      final cleared = withMeta.copyWith(
        clearCustomModelName: true,
        clearCustomModelInputWidth: true,
        clearCustomModelInputHeight: true,
        clearCustomModelClassCount: true,
        clearCustomModelQuantType: true,
      );

      expect(cleared.customModelName, isNull);
      expect(cleared.customModelInputWidth, isNull);
      expect(cleared.customModelInputHeight, isNull);
      expect(cleared.customModelClassCount, isNull);
      expect(cleared.customModelQuantType, isNull);
    });
  });
}
