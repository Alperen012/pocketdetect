import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum CameraFrameFormat { yuv420, bgra8888 }

/// Raw camera frame in plain, isolate-sendable form, so conversion can run
/// off the UI thread.
///
/// For [CameraFrameFormat.yuv420] the three planes are Y, U and V. The U/V
/// planes share [uvRowStride] and [uvPixelStride]; on most Android devices
/// they are interleaved, so [uvPixelStride] is 2 rather than 1.
/// For [CameraFrameFormat.bgra8888] only [plane0] is used.
class CameraFrameData {
  const CameraFrameData({
    required this.format,
    required this.width,
    required this.height,
    required this.plane0,
    required this.rowStride0,
    this.plane1,
    this.plane2,
    this.uvRowStride = 0,
    this.uvPixelStride = 1,
    this.rotationDegrees = 0,
  });

  final CameraFrameFormat format;
  final int width;
  final int height;
  final Uint8List plane0;
  final int rowStride0;
  final Uint8List? plane1;
  final Uint8List? plane2;
  final int uvRowStride;
  final int uvPixelStride;

  /// Clockwise rotation, in degrees (0/90/180/270), that makes the frame
  /// upright. See [frameRotationDegrees].
  final int rotationDegrees;
}

/// Clockwise rotation needed to turn a raw camera frame upright.
///
/// [sensorOrientation] is `CameraDescription.sensorOrientation`;
/// [deviceOrientationDegrees] is 0 for portrait-up, 90 for landscape-left,
/// 180 for portrait-down, 270 for landscape-right.
int frameRotationDegrees({
  required int sensorOrientation,
  required int deviceOrientationDegrees,
  required bool isFrontCamera,
}) {
  final delta = isFrontCamera
      ? sensorOrientation + deviceOrientationDegrees
      : sensorOrientation - deviceOrientationDegrees;
  return ((delta % 360) + 360) % 360;
}

/// Converts [frame] to an upright RGB image. Top-level so it can run in
/// `compute()`.
img.Image convertCameraFrame(CameraFrameData frame) {
  final rgb = switch (frame.format) {
    CameraFrameFormat.yuv420 => _yuv420ToRgb(frame),
    CameraFrameFormat.bgra8888 => _bgraToRgb(frame),
  };
  final image = img.Image.fromBytes(
    width: frame.width,
    height: frame.height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
  if (frame.rotationDegrees % 360 == 0) {
    return image;
  }
  return img.copyRotate(image, angle: frame.rotationDegrees);
}

Uint8List _yuv420ToRgb(CameraFrameData f) {
  final width = f.width;
  final height = f.height;
  final yBytes = f.plane0;
  final uBytes = f.plane1!;
  final vBytes = f.plane2!;
  final out = Uint8List(width * height * 3);

  var o = 0;
  for (var y = 0; y < height; y++) {
    final yRow = y * f.rowStride0;
    final uvRow = (y >> 1) * f.uvRowStride;
    for (var x = 0; x < width; x++) {
      final uvIndex = uvRow + (x >> 1) * f.uvPixelStride;
      final yVal = yBytes[yRow + x];
      final uVal = uBytes[uvIndex] - 128;
      final vVal = vBytes[uvIndex] - 128;

      out[o++] = _clamp255(yVal + 1.370705 * vVal);
      out[o++] = _clamp255(yVal - 0.337633 * uVal - 0.698001 * vVal);
      out[o++] = _clamp255(yVal + 1.732446 * uVal);
    }
  }
  return out;
}

Uint8List _bgraToRgb(CameraFrameData f) {
  final width = f.width;
  final height = f.height;
  final bytes = f.plane0;
  final out = Uint8List(width * height * 3);

  var o = 0;
  for (var y = 0; y < height; y++) {
    final row = y * f.rowStride0;
    for (var x = 0; x < width; x++) {
      final i = row + x * 4;
      out[o++] = bytes[i + 2];
      out[o++] = bytes[i + 1];
      out[o++] = bytes[i];
    }
  }
  return out;
}

int _clamp255(double v) => v < 0 ? 0 : (v > 255 ? 255 : v.toInt());
