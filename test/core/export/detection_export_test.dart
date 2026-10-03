import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:mobile_yolo/core/export/detection_export.dart';
import 'package:mobile_yolo/core/models/detected_object.dart';

DetectedObject det(String label, double conf, Rect box) =>
    DetectedObject(label: label, confidence: conf, boundingBox: box);

DetectionExport sample({
  List<DetectedObject>? detections,
  int? width = 200,
  int? height = 100,
}) {
  return DetectionExport(
    imageName: 'photo.jpg',
    modelName: 'YOLO26 Nano (INT8)',
    inferenceMs: 42,
    timestamp: DateTime.utc(2026, 5, 1, 12),
    imageWidth: width,
    imageHeight: height,
    detections:
        detections ??
        <DetectedObject>[
          det('person', 0.91234, const Rect.fromLTWH(0.1, 0.2, 0.3, 0.4)),
          det('person', 0.5, const Rect.fromLTWH(0.5, 0.5, 0.25, 0.25)),
          det('dog', 0.7, const Rect.fromLTWH(0, 0, 1, 1)),
        ],
  );
}

void main() {
  group('detectionsToJson', () {
    test('contains metadata, counts and normalized + pixel boxes', () {
      final json =
          jsonDecode(detectionsToJson(sample())) as Map<String, dynamic>;

      expect(json['image'], 'photo.jpg');
      expect(json['model'], 'YOLO26 Nano (INT8)');
      expect(json['inferenceMs'], 42);
      expect(json['timestamp'], '2026-05-01T12:00:00.000Z');
      expect(json['imageSize'], <String, dynamic>{'width': 200, 'height': 100});
      expect(json['count'], 3);
      expect(json['countByClass'], <String, dynamic>{'person': 2, 'dog': 1});

      final first =
          (json['detections'] as List<dynamic>).first as Map<String, dynamic>;
      expect(first['label'], 'person');
      expect(first['confidence'], 0.9123);
      expect(first['box'], <String, dynamic>{
        'x': 0.1,
        'y': 0.2,
        'width': 0.3,
        'height': 0.4,
      });
      expect(first['boxPx'], <String, dynamic>{
        'x': 20,
        'y': 20,
        'width': 60,
        'height': 40,
      });
    });

    test('omits pixel data when the image size is unknown', () {
      final json =
          jsonDecode(detectionsToJson(sample(width: null, height: null)))
              as Map<String, dynamic>;

      expect(json.containsKey('imageSize'), isFalse);
      final first =
          (json['detections'] as List<dynamic>).first as Map<String, dynamic>;
      expect(first.containsKey('boxPx'), isFalse);
    });

    test('an empty result is valid JSON with count 0', () {
      final json =
          jsonDecode(detectionsToJson(sample(detections: <DetectedObject>[])))
              as Map<String, dynamic>;

      expect(json['count'], 0);
      expect(json['detections'], isEmpty);
    });
  });

  group('detectionsToCsv', () {
    test('has a header and one row per detection', () {
      final lines = detectionsToCsv(sample()).trimRight().split('\r\n');

      expect(
        lines.first,
        'label,confidence,x,y,width,height,x_px,y_px,width_px,height_px',
      );
      expect(lines, hasLength(4));
      expect(lines[1], 'person,0.9123,0.1,0.2,0.3,0.4,20,20,60,40');
    });

    test('drops the pixel columns without an image size', () {
      final lines = detectionsToCsv(
        sample(width: null, height: null),
      ).trimRight().split('\r\n');

      expect(lines.first, 'label,confidence,x,y,width,height');
      expect(lines[1], 'person,0.9123,0.1,0.2,0.3,0.4');
    });

    test('quotes labels containing commas, quotes and newlines', () {
      final csv = detectionsToCsv(
        sample(
          detections: <DetectedObject>[
            det('a,b', 0.5, const Rect.fromLTWH(0, 0, 1, 1)),
            det('say "hi"', 0.5, const Rect.fromLTWH(0, 0, 1, 1)),
            det('two\nlines', 0.5, const Rect.fromLTWH(0, 0, 1, 1)),
          ],
        ),
      );

      expect(csv, contains('"a,b",'));
      expect(csv, contains('"say ""hi""",'));
      expect(csv, contains('"two\nlines",'));
    });

    test('neutralizes labels a spreadsheet would run as a formula', () {
      final csv = detectionsToCsv(
        sample(
          detections: <DetectedObject>[
            det('=HYPERLINK("http://x")', 0.5, const Rect.fromLTWH(0, 0, 1, 1)),
            det('+1', 0.5, const Rect.fromLTWH(0, 0, 1, 1)),
            det('@cmd', 0.5, const Rect.fromLTWH(0, 0, 1, 1)),
          ],
        ),
      );

      final rows = csv.trimRight().split('\r\n').skip(1).toList();
      expect(rows[0], startsWith('"\'=HYPERLINK'));
      expect(rows[1], startsWith("'+1,"));
      expect(rows[2], startsWith("'@cmd,"));
    });
  });

  group('drawDetections', () {
    test('draws the box on a copy and leaves the source untouched', () {
      final source = img.Image(width: 100, height: 100);
      img.fill(source, color: img.ColorRgb8(0, 0, 0));

      final out = drawDetections(source, <DetectedObject>[
        det('x', 0.9, const Rect.fromLTWH(0.2, 0.4, 0.5, 0.4)),
      ]);

      // Top edge of the box (y = 40) is painted with the first palette colour.
      final edge = out.getPixel(40, 40);
      expect((edge.r, edge.g, edge.b), (0x00, 0xBC, 0xD4));
      // Source is unchanged.
      expect(source.getPixel(40, 40).r, 0);
      // A pixel far from the box is untouched.
      expect(out.getPixel(95, 95).r, 0);
    });

    test('boxes touching the image edge do not throw', () {
      final source = img.Image(width: 50, height: 50);
      expect(
        () => drawDetections(source, <DetectedObject>[
          det('edge', 0.9, const Rect.fromLTWH(0, 0, 1, 1)),
        ]),
        returnsNormally,
      );
    });

    test('annotatedPng returns a decodable PNG of the same size', () {
      final source = img.Image(width: 64, height: 48);
      final bytes = annotatedPng(source, <DetectedObject>[
        det('x', 0.9, const Rect.fromLTWH(0.1, 0.1, 0.5, 0.5)),
      ]);

      final decoded = img.decodePng(bytes)!;
      expect((decoded.width, decoded.height), (64, 48));
    });
  });

  group('renderAnnotatedFromBytes', () {
    test('annotates an encoded photo and returns a PNG', () {
      final source = img.Image(width: 80, height: 60);
      img.fill(source, color: img.ColorRgb8(0, 0, 0));
      final jpg = Uint8List.fromList(img.encodeJpg(source));

      final png = renderAnnotatedFromBytes(
        AnnotateRequest(
          imageBytes: jpg,
          detections: <DetectedObject>[
            det('x', 0.9, const Rect.fromLTWH(0.2, 0.2, 0.5, 0.5)),
          ],
        ),
      )!;

      final decoded = img.decodePng(png)!;
      expect((decoded.width, decoded.height), (80, 60));
      // Something was drawn: not every pixel is still black.
      var painted = 0;
      for (final px in decoded) {
        if (px.r > 0 || px.g > 0 || px.b > 0) painted++;
      }
      expect(painted, greaterThan(0));
    });

    test('applies EXIF orientation like the detector, so boxes line up', () {
      final source = img.Image(width: 80, height: 40)
        ..exif.imageIfd.orientation = 6;
      final jpg = Uint8List.fromList(img.encodeJpg(source));

      final png = renderAnnotatedFromBytes(
        AnnotateRequest(imageBytes: jpg, detections: const <DetectedObject>[]),
      )!;

      final decoded = img.decodePng(png)!;
      expect((decoded.width, decoded.height), (40, 80));
    });

    test('returns null for bytes that are not an image', () {
      expect(
        renderAnnotatedFromBytes(
          AnnotateRequest(
            imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
            detections: const <DetectedObject>[],
          ),
        ),
        isNull,
      );
    });
  });
}
