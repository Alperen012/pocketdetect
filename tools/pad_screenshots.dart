// Pads raw device screenshots to at most 2:1 (a Play Store limit) with the app's
// background colour, writing the results next to the originals as *_play.png.
//
//   dart run tools/pad_screenshots.dart docs/play/screenshots
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'docs/play/screenshots' : args.first);
  final background = img.ColorRgba8(0x0F, 0x17, 0x22, 255);
  for (final entity in dir.listSync()) {
    if (entity is! File ||
        !entity.path.endsWith('.png') ||
        entity.path.endsWith('_play.png')) {
      continue;
    }
    final source = img.decodePng(entity.readAsBytesSync())!;
    final minWidth = (source.height / 2).ceil();
    if (source.width >= minWidth) continue;
    final out = img.Image(
      width: minWidth,
      height: source.height,
      numChannels: 4,
    );
    img.fill(out, color: background);
    img.compositeImage(out, source, dstX: (minWidth - source.width) ~/ 2);
    final target = entity.path.replaceFirst(RegExp(r'\.png$'), '_play.png');
    File(target).writeAsBytesSync(img.encodePng(out));
    stdout.writeln('$target ${out.width}x${out.height}');
  }
}
