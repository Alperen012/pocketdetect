import 'package:flutter/foundation.dart';

/// Geometry of fitting a source image into a square model input while
/// preserving aspect ratio (the YOLO "letterbox" transform).
///
/// All values are in model-input pixels. [padX]/[padY] are the gray borders
/// added on the left/top; [scaledWidth]/[scaledHeight] is the area actually
/// covered by the image.
@immutable
class LetterboxParams {
  const LetterboxParams({
    required this.inputSize,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.scaledWidth,
    required this.scaledHeight,
    required this.padX,
    required this.padY,
  });

  factory LetterboxParams.compute({
    required int sourceWidth,
    required int sourceHeight,
    required int inputSize,
  }) {
    final scaleW = inputSize / sourceWidth;
    final scaleH = inputSize / sourceHeight;
    final scale = scaleW < scaleH ? scaleW : scaleH;
    final scaledWidth = (sourceWidth * scale).round();
    final scaledHeight = (sourceHeight * scale).round();
    return LetterboxParams(
      inputSize: inputSize,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      scaledWidth: scaledWidth,
      scaledHeight: scaledHeight,
      padX: (inputSize - scaledWidth) ~/ 2,
      padY: (inputSize - scaledHeight) ~/ 2,
    );
  }

  final int inputSize;
  final int sourceWidth;
  final int sourceHeight;
  final int scaledWidth;
  final int scaledHeight;
  final int padX;
  final int padY;
}

/// Size to pre-downscale a [width]x[height] image to so its longest side is
/// at most [maxSide]. Returns the original size when it already fits.
({int width, int height}) capLongestSide(int width, int height, int maxSide) {
  final longest = width > height ? width : height;
  if (longest <= maxSide) {
    return (width: width, height: height);
  }
  final scale = maxSide / longest;
  return (width: (width * scale).round(), height: (height * scale).round());
}
