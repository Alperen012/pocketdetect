import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/detection/letterbox.dart';

void main() {
  group('LetterboxParams.compute', () {
    test('wide image gets vertical padding only', () {
      final p = LetterboxParams.compute(
        sourceWidth: 1280,
        sourceHeight: 640,
        inputSize: 640,
      );
      expect(p.scaledWidth, 640);
      expect(p.scaledHeight, 320);
      expect(p.padX, 0);
      expect(p.padY, 160);
    });

    test('tall image gets horizontal padding only', () {
      final p = LetterboxParams.compute(
        sourceWidth: 480,
        sourceHeight: 960,
        inputSize: 640,
      );
      expect(p.scaledWidth, 320);
      expect(p.scaledHeight, 640);
      expect(p.padX, 160);
      expect(p.padY, 0);
    });

    test('square image fills the input', () {
      final p = LetterboxParams.compute(
        sourceWidth: 100,
        sourceHeight: 100,
        inputSize: 640,
      );
      expect(p.scaledWidth, 640);
      expect(p.scaledHeight, 640);
      expect(p.padX, 0);
      expect(p.padY, 0);
    });

    test('small image is scaled up to the input', () {
      final p = LetterboxParams.compute(
        sourceWidth: 160,
        sourceHeight: 80,
        inputSize: 320,
      );
      expect(p.scaledWidth, 320);
      expect(p.scaledHeight, 160);
      expect(p.padY, 80);
    });

    test('odd padding rounds down', () {
      final p = LetterboxParams.compute(
        sourceWidth: 100,
        sourceHeight: 99,
        inputSize: 100,
      );
      expect(p.scaledHeight, 99);
      expect(p.padY, 0);
    });
  });

  group('capLongestSide', () {
    test('returns the original size when it already fits', () {
      final s = capLongestSide(500, 300, 640);
      expect((s.width, s.height), (500, 300));
    });

    test('downscales proportionally on the longest side', () {
      final s = capLongestSide(4000, 2000, 1000);
      expect((s.width, s.height), (1000, 500));
    });

    test('works for portrait images', () {
      final s = capLongestSide(1500, 3000, 600);
      expect((s.width, s.height), (300, 600));
    });
  });
}
