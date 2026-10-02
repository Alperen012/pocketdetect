import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/detection/tensor_io.dart';

/// The nested-list builders the app used before the flat buffers, kept here
/// as the reference the new code must match.
List<int> legacyInt8Flat(Uint8List rgb, int w, int h, double s, int zp) {
  final nested = List<List<List<int>>>.generate(
    h,
    (y) => List<List<int>>.generate(w, (x) {
      final idx = (y * w + x) * 3;
      return <int>[
        (rgb[idx] / 255.0 / s + zp).round(),
        (rgb[idx + 1] / 255.0 / s + zp).round(),
        (rgb[idx + 2] / 255.0 / s + zp).round(),
      ];
    }),
  );
  return nested.expand((r) => r).expand((p) => p).toList();
}

List<double> legacyFloatFlat(Uint8List rgb, int w, int h) {
  final nested = List<List<List<double>>>.generate(
    h,
    (y) => List<List<double>>.generate(w, (x) {
      final idx = (y * w + x) * 3;
      return <double>[rgb[idx] / 255.0, rgb[idx + 1] / 255.0, rgb[idx + 2] / 255.0];
    }),
  );
  return nested.expand((r) => r).expand((p) => p).toList();
}

Uint8List sampleRgb(int w, int h) {
  final bytes = Uint8List(w * h * 3);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = (i * 37 + 11) % 256;
  }
  return bytes;
}

void main() {
  group('buildInputBytes', () {
    test('int8 matches the legacy nested tensor, in range', () {
      const w = 5, h = 4;
      final rgb = sampleRgb(w, h);
      const scale = 1 / 255.0, zp = -128; // typical full-range int8 input

      final bytes = buildInputBytes(InputBuildRequest(
        rgbBytes: rgb,
        width: w,
        height: h,
        isInt8: true,
        scale: scale,
        zeroPoint: zp,
      ));

      expect(bytes.length, w * h * 3);
      expect(
        Int8List.sublistView(bytes).toList(),
        legacyInt8Flat(rgb, w, h, scale, zp),
      );
    });

    test('int8 clamps values the legacy path would have wrapped', () {
      final bytes = buildInputBytes(InputBuildRequest(
        rgbBytes: Uint8List.fromList(<int>[0, 128, 255]),
        width: 1,
        height: 1,
        isInt8: true,
        scale: 0.5 / 255.0, // doubles the range: 255 -> 2*255 - 128 = 382
        zeroPoint: -128,
      ));

      final q = Int8List.sublistView(bytes).toList();
      expect(q.first, -128);
      expect(q.last, 127);
    });

    test('float32 matches the legacy nested tensor', () {
      const w = 6, h = 3;
      final rgb = sampleRgb(w, h);

      final bytes = buildInputBytes(InputBuildRequest(
        rgbBytes: rgb,
        width: w,
        height: h,
        isInt8: false,
        scale: 1,
        zeroPoint: 0,
      ));

      expect(bytes.length, w * h * 3 * 4);
      final values = bytes.buffer.asFloat32List();
      final legacy = legacyFloatFlat(rgb, w, h);
      for (var i = 0; i < legacy.length; i++) {
        expect(values[i], closeTo(legacy[i], 1e-6));
      }
    });
  });

  group('parseOutputBytes', () {
    test('int8 is split per channel and dequantized', () {
      // 2 channels x 3 anchors, row-major.
      final raw = Int8List.fromList(<int>[10, 20, 30, -5, 0, 5]);
      const scale = 0.1;
      const zp = 5;

      final channels = parseOutputBytes(
        raw.buffer.asUint8List(),
        isInt8: true,
        channels: 2,
        count: 3,
        scale: scale,
        zeroPoint: zp,
      );

      expect(channels, hasLength(2));
      expect(channels[0], <double>[
        (10 - zp) * scale,
        (20 - zp) * scale,
        (30 - zp) * scale,
      ]);
      expect(channels[1], <double>[
        (-5 - zp) * scale,
        (0 - zp) * scale,
        (5 - zp) * scale,
      ]);
    });

    test('float32 is split per channel unchanged', () {
      final raw = Float32List.fromList(<double>[0.25, 0.5, 0.75, 1, 2, 3]);

      final channels = parseOutputBytes(
        raw.buffer.asUint8List(),
        isInt8: false,
        channels: 2,
        count: 3,
        scale: 0,
        zeroPoint: 0,
      );

      expect(channels[0], <double>[0.25, 0.5, 0.75]);
      expect(channels[1], <double>[1, 2, 3]);
    });

    test('float32 works when the source bytes are an unaligned view', () {
      final raw = Float32List.fromList(<double>[1.5, 2.5]);
      final padded = Uint8List(1 + raw.lengthInBytes)
        ..setRange(1, 1 + raw.lengthInBytes, raw.buffer.asUint8List());
      final unaligned = Uint8List.sublistView(padded, 1);

      final channels = parseOutputBytes(
        unaligned,
        isInt8: false,
        channels: 1,
        count: 2,
        scale: 0,
        zeroPoint: 0,
      );

      expect(channels.single, <double>[1.5, 2.5]);
    });

    test('result does not change when the source buffer is overwritten', () {
      final raw = Float32List.fromList(<double>[1, 2]);
      final bytes = raw.buffer.asUint8List();

      final channels = parseOutputBytes(
        bytes,
        isInt8: false,
        channels: 1,
        count: 2,
        scale: 0,
        zeroPoint: 0,
      );
      raw[0] = 99; // simulates the interpreter reusing its output memory

      expect(channels.single, <double>[1, 2]);
    });
  });
}
