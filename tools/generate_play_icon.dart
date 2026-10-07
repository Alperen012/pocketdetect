// Writes the 512x512 Play Store app icon to docs/play/icon_512.png.
//
//   dart run tools/generate_play_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final source = img.decodePng(File('assets/icon/icon.png').readAsBytesSync())!;
  final icon = img.copyResize(
    source,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.cubic,
  );
  File('docs/play/icon_512.png').writeAsBytesSync(img.encodePng(icon));
  stdout.writeln('Wrote docs/play/icon_512.png');
}
