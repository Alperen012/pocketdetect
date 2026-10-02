import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/features/capture/widgets/bounding_box_overlay.dart';

void main() {
  group('scaleNormalizedBox', () {
    test('scales normalized coordinates to the canvas size', () {
      final r = scaleNormalizedBox(
        const Rect.fromLTWH(0.25, 0.5, 0.5, 0.25),
        const Size(400, 800),
      );
      expect(r, const Rect.fromLTWH(100, 400, 200, 200));
    });

    test('a full-frame box fills the canvas', () {
      final r = scaleNormalizedBox(
        const Rect.fromLTWH(0, 0, 1, 1),
        const Size(360, 640),
      );
      expect(r, const Rect.fromLTWH(0, 0, 360, 640));
    });
  });
}
