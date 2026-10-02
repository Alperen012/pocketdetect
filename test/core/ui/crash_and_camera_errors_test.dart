import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/detection/camera_errors.dart';
import 'package:mobile_yolo/core/ui/crash_screen.dart';

void main() {
  group('CrashMessages.forLanguage', () {
    test('Turkish for tr', () {
      expect(CrashMessages.forLanguage('tr'), same(CrashMessages.turkish));
    });

    test('English for English and for any other language', () {
      expect(CrashMessages.forLanguage('en'), same(CrashMessages.english));
      expect(CrashMessages.forLanguage('de'), same(CrashMessages.english));
      expect(CrashMessages.forLanguage(''), same(CrashMessages.english));
    });

    test('both languages have non-empty texts', () {
      for (final m in <CrashMessages>[
        CrashMessages.english,
        CrashMessages.turkish,
      ]) {
        expect(m.title, isNotEmpty);
        expect(m.restartHint, isNotEmpty);
      }
    });
  });

  group('isCameraPermissionError', () {
    test('recognises the camera plugin permission codes', () {
      for (final code in <String>[
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      ]) {
        expect(isCameraPermissionError(CameraException(code, 'x')), isTrue,
            reason: code);
      }
    });

    test('other camera errors are not permission errors', () {
      expect(isCameraPermissionError(CameraException('cameraNotFound', 'x')),
          isFalse);
      expect(isCameraPermissionError(CameraException('AudioAccessDenied', 'x')),
          isFalse);
    });

    test('non-camera errors and null are not permission errors', () {
      expect(isCameraPermissionError(StateError('x')), isFalse);
      expect(isCameraPermissionError(null), isFalse);
    });
  });
}
