// Draws the launcher icon sources into assets/icon/.
//
//   dart run tools/generate_icon.dart
//   dart run flutter_launcher_icons
//
// icon.png is the full legacy icon; icon_foreground.png is the transparent
// adaptive-icon foreground, drawn inside the central safe zone.
import 'dart:io';

import 'package:image/image.dart' as img;

const int _size = 1024;
final img.Color _background = img.ColorRgba8(0x0F, 0x17, 0x22, 255);
final img.Color _primary = img.ColorRgba8(0x1B, 0x63, 0xFF, 255);
final img.Color _accent = img.ColorRgba8(0x22, 0xD3, 0xEE, 255);

/// Draws the mark inside a square of [span] pixels starting at ([ox], [oy]).
void _drawMark(img.Image canvas, double ox, double oy, double span) {
  double x(double f) => ox + f * span;
  double y(double f) => oy + f * span;
  int px(double f) => f.round();

  void bar(double l, double t, double r, double b, img.Color c, int radius) {
    img.fillRect(
      canvas,
      x1: px(x(l)),
      y1: px(y(t)),
      x2: px(x(r)),
      y2: px(y(b)),
      color: c,
      radius: radius,
    );
  }

  final int thick = (span * 0.055).round();
  final double lo = 0.06;
  final double hi = 0.94;
  final double arm = 0.24;
  final double t = 0.055;

  // Viewfinder corners.
  for (final bool right in <bool>[false, true]) {
    for (final bool bottom in <bool>[false, true]) {
      final double cx = right ? hi : lo;
      final double cy = bottom ? hi : lo;
      final double hx0 = right ? cx - arm : cx;
      final double hx1 = right ? cx : cx + arm;
      final double vy0 = bottom ? cy - arm : cy;
      final double vy1 = bottom ? cy : cy + arm;
      // Horizontal arm, then vertical arm; they overlap in the corner.
      bar(
        hx0,
        bottom ? cy - t : cy,
        hx1,
        bottom ? cy : cy + t,
        _accent,
        thick ~/ 2,
      );
      bar(
        right ? cx - t : cx,
        vy0,
        right ? cx : cx + t,
        vy1,
        _accent,
        thick ~/ 2,
      );
    }
  }

  // Detection box (four bars, so the outline stays solid and the foreground
  // layer stays transparent inside) with its label tag.
  const double bl = 0.27, bt = 0.40, br = 0.73, bb = 0.74, bw = 0.05;
  final int r = (span * 0.025).round();
  bar(bl, bt, br, bt + bw, _primary, r);
  bar(bl, bb - bw, br, bb, _primary, r);
  bar(bl, bt, bl + bw, bb, _primary, r);
  bar(br - bw, bt, br, bb, _primary, r);
  bar(0.27, 0.27, 0.52, 0.375, _primary, (span * 0.03).round());

  // Centre dot.
  img.fillCircle(
    canvas,
    x: px(x(0.50)),
    y: px(y(0.57)),
    radius: (span * 0.06).round(),
    color: _accent,
  );
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Legacy icon: full bleed on the dark background.
  final full = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(full, color: _background);
  _drawMark(full, _size * 0.14, _size * 0.14, _size * 0.72);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(full));

  // Adaptive foreground: transparent, mark kept inside the 66% safe zone.
  final fg = img.Image(width: _size, height: _size, numChannels: 4);
  _drawMark(fg, _size * 0.21, _size * 0.21, _size * 0.58);
  File('assets/icon/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));

  stdout.writeln('Wrote assets/icon/icon.png and icon_foreground.png');
}
