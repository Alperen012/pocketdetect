import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Decodes [bytes] and applies the EXIF orientation, so the pixels match what
/// Flutter's `Image` widget shows (which honours EXIF). Without this, a
/// portrait photo stored sideways would be detected sideways and the boxes
/// would not line up with the displayed picture.
///
/// Returns null when [bytes] is not a decodable image. Format sniffing in the
/// `image` package can throw (e.g. a `RangeError` on a truncated file), so any
/// failure is treated as "not an image".
img.Image? decodeUpright(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return img.bakeOrientation(decoded);
  } catch (_) {
    return null;
  }
}
