import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Input for [buildInputBytes]. Must stay sendable to a `compute()` isolate.
@immutable
class InputBuildRequest {
  const InputBuildRequest({
    required this.rgbBytes,
    required this.width,
    required this.height,
    required this.isInt8,
    required this.scale,
    required this.zeroPoint,
  });

  /// `width * height * 3` bytes, RGB, row-major.
  final Uint8List rgbBytes;
  final int width;
  final int height;
  final bool isInt8;

  /// Input quantization (used only when [isInt8]).
  final double scale;
  final int zeroPoint;
}

/// Builds the model's `[1, H, W, 3]` input tensor as raw bytes, ready for
/// `Interpreter.runInference`.
///
/// int8 models get `round(v / 255 / scale + zeroPoint)` clamped to the int8
/// range; float32 models get `v / 255`. This is the flat equivalent of the
/// nested-list tensor `Interpreter.run` would flatten, without allocating a
/// list per pixel. Top-level so it can run in `compute()`.
Uint8List buildInputBytes(InputBuildRequest r) {
  final count = r.width * r.height * 3;
  final src = r.rgbBytes;

  if (r.isInt8) {
    final out = Int8List(count);
    final scale = r.scale;
    for (var i = 0; i < count; i++) {
      // Same expression as the old nested-list path, so rounding is identical.
      final q = (src[i] / 255.0 / scale + r.zeroPoint).round();
      out[i] = q < -128 ? -128 : (q > 127 ? 127 : q);
    }
    return out.buffer.asUint8List();
  }

  final out = Float32List(count);
  for (var i = 0; i < count; i++) {
    out[i] = src[i] / 255.0;
  }
  return out.buffer.asUint8List();
}

/// Splits a raw `[1, channels, count]` output tensor into one list per
/// channel, dequantizing int8 output with [scale] / [zeroPoint].
///
/// [bytes] must be a copy owned by the caller, not a live view of native
/// tensor memory.
List<List<double>> parseOutputBytes(
  Uint8List bytes, {
  required bool isInt8,
  required int channels,
  required int count,
  required double scale,
  required int zeroPoint,
}) {
  final result = <List<double>>[];

  if (isInt8) {
    final values = Int8List.sublistView(bytes, 0, channels * count);
    for (var c = 0; c < channels; c++) {
      final channel = Float64List(count);
      final base = c * count;
      for (var i = 0; i < count; i++) {
        channel[i] = (values[base + i] - zeroPoint) * scale;
      }
      result.add(channel);
    }
    return result;
  }

  // float32: a fresh copy starts at offset 0 of its own buffer, so a Float32
  // view over it is always correctly aligned.
  final values =
      Uint8List.fromList(bytes).buffer.asFloat32List(0, channels * count);
  for (var c = 0; c < channels; c++) {
    result.add(Float32List.sublistView(values, c * count, (c + 1) * count));
  }
  return result;
}
