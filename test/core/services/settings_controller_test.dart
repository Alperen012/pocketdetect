import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/models/resolution_profile.dart';
import 'package:mobile_yolo/core/services/settings_controller.dart';

void main() {
  group('SettingsController', () {
    late SharedPreferences prefs;
    late SettingsController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      controller = SettingsController(prefs);
    });

    test('initial settings match AppSettings.defaults', () {
      final s = controller.settings;

      expect(s.modelId, 'yolo26_nano');
      expect(s.confidenceThreshold, 0.5);
      expect(s.iouThreshold, 0.45);
      expect(s.useNms, true);
      expect(s.maxDetections, 100);
      expect(s.useCustomModel, false);
    });

    test('updateConfidence() changes threshold and notifies', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.updateConfidence(0.75);

      expect(controller.settings.confidenceThreshold, 0.75);
      expect(notified, true);
    });

    test('updateIou() changes threshold and notifies', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.updateIou(0.6);

      expect(controller.settings.iouThreshold, 0.6);
      expect(notified, true);
    });

    test('updateUseNms() toggles NMS and notifies', () {
      controller.updateUseNms(false);
      expect(controller.settings.useNms, false);

      controller.updateUseNms(true);
      expect(controller.settings.useNms, true);
    });

    test('updateMaxDetections() changes value', () {
      controller.updateMaxDetections(50);
      expect(controller.settings.maxDetections, 50);
    });

    test('updateResolution() changes profile', () {
      controller.updateResolution(ResolutionProfile.fast);
      expect(controller.settings.resolutionProfile.id, 'fast');
    });

    test('toggleLabel() adds and removes labels', () {
      // Initially all COCO labels are selected
      final initialCount = controller.selectedLabels.length;

      // Remove one
      controller.toggleLabel('person');
      expect(controller.selectedLabels.contains('person'), false);
      expect(controller.selectedLabels.length, initialCount - 1);

      // Add it back
      controller.toggleLabel('person');
      expect(controller.selectedLabels.contains('person'), true);
      expect(controller.selectedLabels.length, initialCount);
    });

    test('updateCustomModelPath() sets path', () {
      controller.updateCustomModelPath('/path/to/model.tflite');
      expect(
          controller.settings.customModelPath, '/path/to/model.tflite');
    });

    test('clearCustomModelMetadata() nulls out all custom fields', () {
      controller.updateCustomModelMetadata(
        name: 'Custom',
        inputWidth: 640,
        inputHeight: 640,
        classCount: 80,
        quantType: 'int8',
      );
      expect(controller.settings.customModelName, 'Custom');

      controller.clearCustomModelMetadata();
      expect(controller.settings.customModelName, isNull);
      expect(controller.settings.customModelInputWidth, isNull);
      expect(controller.settings.customModelInputHeight, isNull);
      expect(controller.settings.customModelClassCount, isNull);
      expect(controller.settings.customModelQuantType, isNull);
    });

    test('resetToDefaults() restores everything', () {
      // Change several settings
      controller.updateConfidence(0.9);
      controller.updateIou(0.1);
      controller.updateMaxDetections(10);
      controller.updateUseNms(false);

      // Reset
      controller.resetToDefaults();

      expect(controller.settings.confidenceThreshold, 0.5);
      expect(controller.settings.iouThreshold, 0.45);
      expect(controller.settings.maxDetections, 100);
      expect(controller.settings.useNms, true);
    });

    test('settings persist across reconstruction', () {
      controller.updateConfidence(0.8);
      controller.updateMaxDetections(25);

      // Reconstruct
      final controller2 = SettingsController(prefs);

      expect(controller2.settings.confidenceThreshold, 0.8);
      expect(controller2.settings.maxDetections, 25);
    });

    test('markLowMemoryWarningSeen() persists', () {
      expect(controller.settings.lowMemoryWarningSeen, false);
      controller.markLowMemoryWarningSeen();
      expect(controller.settings.lowMemoryWarningSeen, true);
    });
  });
}
