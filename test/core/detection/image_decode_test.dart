import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:mobile_yolo/core/detection/image_decode.dart';

Uint8List jpegWithOrientation(int width, int height, int? orientation) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 30, 30));
  if (orientation != null) {
    image.exif.imageIfd.orientation = orientation;
  }
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  group('decodeUpright', () {
    test('returns the image as is when there is no orientation', () {
      final decoded = decodeUpright(jpegWithOrientation(40, 20, null))!;

      expect((decoded.width, decoded.height), (40, 20));
    });

    test('rotates a sideways photo (EXIF 6) so it is upright', () {
      // Stored landscape 40x20, but the camera says "rotate 90° to view".
      final decoded = decodeUpright(jpegWithOrientation(40, 20, 6))!;

      expect((decoded.width, decoded.height), (20, 40));
    });

    test('keeps EXIF 1 (normal) unchanged', () {
      final decoded = decodeUpright(jpegWithOrientation(40, 20, 1))!;

      expect((decoded.width, decoded.height), (40, 20));
    });

    test('returns null for bytes that are not an image', () {
      expect(decodeUpright(Uint8List.fromList(<int>[1, 2, 3])), isNull);
    });
  });
}
