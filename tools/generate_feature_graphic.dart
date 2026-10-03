// Draws the 1024x500 Play Store feature graphic into docs/play/feature_graphic.png.
//
//   dart run tools/generate_feature_graphic.dart
//
// Reads assets/icon/icon.png (run tools/generate_icon.dart first).
import 'dart:io';

import 'package:image/image.dart' as img;

img.Image _text(
  String text,
  img.BitmapFont font,
  img.Color color,
  double scale,
) {
  // The bundled bitmap fonts are small; draw big enough, then enlarge smoothly.
  final probe = img.Image(width: 600, height: 80, numChannels: 4);
  img.drawString(probe, text, font: font, x: 0, y: 0, color: color);
  final cropped = img.copyCrop(
    probe,
    x: 0,
    y: 0,
    width: 600,
    height: font.lineHeight + 4,
  );
  return img.copyResize(
    cropped,
    width: (cropped.width * scale).round(),
    height: (cropped.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
}

void main() {
  final canvas = img.Image(width: 1024, height: 500, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0x0F, 0x17, 0x22, 255));

  final icon = img.decodePng(File('assets/icon/icon.png').readAsBytesSync())!;
  final mark = img.copyResize(
    icon,
    width: 300,
    height: 300,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(canvas, mark, dstX: 90, dstY: 100);

  final title = _text(
    'PocketDetect',
    img.arial48,
    img.ColorRgba8(0xF8, 0xFA, 0xFC, 255),
    1.6,
  );
  final tagline = _text(
    'Offline object detection',
    img.arial24,
    img.ColorRgba8(0x22, 0xD3, 0xEE, 255),
    1.5,
  );
  final tagline2 = _text(
    'with your own YOLO models',
    img.arial24,
    img.ColorRgba8(0x9A, 0xA4, 0xB2, 255),
    1.5,
  );
  img.compositeImage(canvas, title, dstX: 420, dstY: 150);
  img.compositeImage(canvas, tagline, dstX: 424, dstY: 250);
  img.compositeImage(canvas, tagline2, dstX: 424, dstY: 295);

  Directory('docs/play').createSync(recursive: true);
  File('docs/play/feature_graphic.png').writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Wrote docs/play/feature_graphic.png');
}
