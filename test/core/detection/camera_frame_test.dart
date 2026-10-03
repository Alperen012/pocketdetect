import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/detection/camera_frame.dart';

void main() {
  group('frameRotationDegrees', () {
    test('back camera, portrait phone, 90° sensor needs a 90° turn', () {
      expect(
        frameRotationDegrees(
          sensorOrientation: 90,
          deviceOrientationDegrees: 0,
          isFrontCamera: false,
        ),
        90,
      );
    });

    test('back camera, landscape-left phone, 90° sensor needs no turn', () {
      expect(
        frameRotationDegrees(
          sensorOrientation: 90,
          deviceOrientationDegrees: 90,
          isFrontCamera: false,
        ),
        0,
      );
    });

    test('back camera result is never negative', () {
      expect(
        frameRotationDegrees(
          sensorOrientation: 90,
          deviceOrientationDegrees: 270,
          isFrontCamera: false,
        ),
        180,
      );
    });

    test('front camera adds the device rotation', () {
      expect(
        frameRotationDegrees(
          sensorOrientation: 270,
          deviceOrientationDegrees: 0,
          isFrontCamera: true,
        ),
        270,
      );
      expect(
        frameRotationDegrees(
          sensorOrientation: 270,
          deviceOrientationDegrees: 90,
          isFrontCamera: true,
        ),
        0,
      );
    });
  });

  group('convertCameraFrame', () {
    // Neutral chroma (128) makes R = G = B = Y.
    Uint8List neutral(int n) => Uint8List(n)..fillRange(0, n, 128);

    test('yuv420 with neutral chroma yields gray pixels from Y', () {
      final y = Uint8List.fromList(<int>[0, 50, 100, 150, 200, 250, 10, 20]);
      final image = convertCameraFrame(
        CameraFrameData(
          format: CameraFrameFormat.yuv420,
          width: 4,
          height: 2,
          plane0: y,
          rowStride0: 4,
          plane1: neutral(2),
          plane2: neutral(2),
          uvRowStride: 2,
          uvPixelStride: 1,
        ),
      );

      expect(image.width, 4);
      expect(image.height, 2);
      expect(image.getPixel(1, 0).r, 50);
      expect(image.getPixel(1, 0).g, 50);
      expect(image.getPixel(1, 0).b, 50);
      expect(image.getPixel(1, 1).r, 250);
    });

    test('honours interleaved chroma (uvPixelStride 2)', () {
      // 4x2 frame -> two chroma samples per row, stored every 2nd byte as on
      // real Android devices (the bytes in between belong to the other
      // plane). Reading with stride 1 would hit the filler bytes instead.
      final y = Uint8List.fromList(List<int>.filled(8, 100));
      final u = Uint8List.fromList(<int>[128, 0, 228, 0]); // samples: 128, 228
      final v = Uint8List.fromList(<int>[128, 0, 128, 0]); // samples: 128, 128

      final image = convertCameraFrame(
        CameraFrameData(
          format: CameraFrameFormat.yuv420,
          width: 4,
          height: 2,
          plane0: y,
          rowStride0: 4,
          plane1: u,
          plane2: v,
          uvRowStride: 4,
          uvPixelStride: 2,
        ),
      );

      // Left half: neutral chroma -> stays gray.
      expect(image.getPixel(0, 0).b, closeTo(100, 1));
      // Right half: U = 228 -> B = 100 + 1.732446 * 100, clamped to 255.
      expect(image.getPixel(2, 0).b, 255);
      expect(image.getPixel(3, 1).b, 255);
    });

    test('respects the Y row stride when rows are padded', () {
      // 2x2 image stored with a 4-byte row stride (2 padding bytes per row).
      final y = Uint8List.fromList(<int>[10, 20, 255, 255, 30, 40, 255, 255]);
      final image = convertCameraFrame(
        CameraFrameData(
          format: CameraFrameFormat.yuv420,
          width: 2,
          height: 2,
          plane0: y,
          rowStride0: 4,
          plane1: neutral(1),
          plane2: neutral(1),
          uvRowStride: 1,
          uvPixelStride: 1,
        ),
      );

      expect(image.getPixel(0, 0).r, 10);
      expect(image.getPixel(1, 0).r, 20);
      expect(image.getPixel(0, 1).r, 30);
      expect(image.getPixel(1, 1).r, 40);
    });

    test('bgra8888 is reordered to rgb', () {
      // One pixel: B=10, G=20, R=30, A=255.
      final image = convertCameraFrame(
        CameraFrameData(
          format: CameraFrameFormat.bgra8888,
          width: 1,
          height: 1,
          plane0: Uint8List.fromList(<int>[10, 20, 30, 255]),
          rowStride0: 4,
        ),
      );

      final p = image.getPixel(0, 0);
      expect((p.r, p.g, p.b), (30, 20, 10));
    });

    test('rotating 90° clockwise moves the left pixel to the top', () {
      // 2x1 frame: left pixel Y=10, right pixel Y=200.
      final image = convertCameraFrame(
        CameraFrameData(
          format: CameraFrameFormat.yuv420,
          width: 2,
          height: 1,
          plane0: Uint8List.fromList(<int>[10, 200]),
          rowStride0: 2,
          plane1: neutral(1),
          plane2: neutral(1),
          uvRowStride: 1,
          uvPixelStride: 1,
          rotationDegrees: 90,
        ),
      );

      expect((image.width, image.height), (1, 2));
      expect(image.getPixel(0, 0).r, 10);
      expect(image.getPixel(0, 1).r, 200);
    });

    test('rotating 180° reverses the pixels', () {
      final image = convertCameraFrame(
        CameraFrameData(
          format: CameraFrameFormat.yuv420,
          width: 2,
          height: 1,
          plane0: Uint8List.fromList(<int>[10, 200]),
          rowStride0: 2,
          plane1: neutral(1),
          plane2: neutral(1),
          uvRowStride: 1,
          uvPixelStride: 1,
          rotationDegrees: 180,
        ),
      );

      expect(image.getPixel(0, 0).r, 200);
      expect(image.getPixel(1, 0).r, 10);
    });
  });
}
