import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../detection/image_decode.dart';
import '../models/detected_object.dart';

/// Everything needed to export one detection run.
class DetectionExport {
  const DetectionExport({
    required this.imageName,
    required this.modelName,
    required this.inferenceMs,
    required this.timestamp,
    required this.detections,
    this.imageWidth,
    this.imageHeight,
  });

  final String imageName;
  final String modelName;
  final int inferenceMs;
  final DateTime timestamp;
  final List<DetectedObject> detections;

  /// Original image size; when known, pixel coordinates are exported too.
  final int? imageWidth;
  final int? imageHeight;

  bool get hasPixelSize =>
      imageWidth != null &&
      imageHeight != null &&
      imageWidth! > 0 &&
      imageHeight! > 0;
}

double _r(double v, [int places = 4]) {
  final f = _pow10[places];
  return (v * f).roundToDouble() / f;
}

const List<double> _pow10 = <double>[1, 10, 100, 1000, 10000, 100000];

/// Pretty-printed JSON. Boxes are normalized (`0..1`, origin top-left) and,
/// when the image size is known, also given in pixels.
String detectionsToJson(DetectionExport e) {
  final byClass = <String, int>{};
  for (final d in e.detections) {
    byClass[d.label] = (byClass[d.label] ?? 0) + 1;
  }

  final map = <String, dynamic>{
    'image': e.imageName,
    if (e.hasPixelSize)
      'imageSize': <String, int>{
        'width': e.imageWidth!,
        'height': e.imageHeight!,
      },
    'model': e.modelName,
    'inferenceMs': e.inferenceMs,
    'timestamp': e.timestamp.toUtc().toIso8601String(),
    'count': e.detections.length,
    'countByClass': byClass,
    'detections': <Map<String, dynamic>>[
      for (final d in e.detections)
        <String, dynamic>{
          'label': d.label,
          'confidence': _r(d.confidence),
          'box': <String, double>{
            'x': _r(d.boundingBox.left),
            'y': _r(d.boundingBox.top),
            'width': _r(d.boundingBox.width),
            'height': _r(d.boundingBox.height),
          },
          if (e.hasPixelSize)
            'boxPx': <String, int>{
              'x': (d.boundingBox.left * e.imageWidth!).round(),
              'y': (d.boundingBox.top * e.imageHeight!).round(),
              'width': (d.boundingBox.width * e.imageWidth!).round(),
              'height': (d.boundingBox.height * e.imageHeight!).round(),
            },
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}

/// CSV with a header row. Normalized box columns always; pixel columns when
/// the image size is known. Fields are quoted per RFC 4180 when needed.
String detectionsToCsv(DetectionExport e) {
  final header = <String>[
    'label',
    'confidence',
    'x',
    'y',
    'width',
    'height',
    if (e.hasPixelSize) ...<String>['x_px', 'y_px', 'width_px', 'height_px'],
  ];

  final rows = <String>[header.join(',')];
  for (final d in e.detections) {
    final b = d.boundingBox;
    final cells = <String>[
      _csv(d.label),
      _r(d.confidence).toString(),
      _r(b.left).toString(),
      _r(b.top).toString(),
      _r(b.width).toString(),
      _r(b.height).toString(),
      if (e.hasPixelSize) ...<String>[
        (b.left * e.imageWidth!).round().toString(),
        (b.top * e.imageHeight!).round().toString(),
        (b.width * e.imageWidth!).round().toString(),
        (b.height * e.imageHeight!).round().toString(),
      ],
    ];
    rows.add(cells.join(','));
  }
  return '${rows.join('\r\n')}\r\n';
}

String _csv(String value) {
  // Labels come from user-supplied files. A leading = + - @ (or tab/CR) would
  // be run as a formula by spreadsheet apps, so neutralize it with a quote.
  var v = value;
  if (v.isNotEmpty && '=+-@\t\r'.contains(v[0])) {
    v = "'$v";
  }
  final needsQuotes =
      v.contains(',') ||
      v.contains('"') ||
      v.contains('\n') ||
      v.contains('\r');
  final escaped = v.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

const List<int> _boxColors = <int>[
  0x00BCD4,
  0xFF9800,
  0x4CAF50,
  0xF44336,
  0x9C27B0,
  0x2196F3,
  0xFFEB3B,
  0xE91E63,
];

/// Returns [source] with each detection's box and label drawn on a copy.
img.Image drawDetections(img.Image source, List<DetectedObject> detections) {
  final image = img.Image.from(source);
  // Scale line width and text with the image so exports stay legible.
  final longest = image.width > image.height ? image.width : image.height;
  final thickness = (longest / 320).round().clamp(2, 8);

  for (var i = 0; i < detections.length; i++) {
    final d = detections[i];
    final rgb = _boxColors[i % _boxColors.length];
    final color = img.ColorRgb8(
      (rgb >> 16) & 0xFF,
      (rgb >> 8) & 0xFF,
      rgb & 0xFF,
    );

    final x1 = (d.boundingBox.left * image.width).round();
    final y1 = (d.boundingBox.top * image.height).round();
    final x2 = (d.boundingBox.right * image.width).round();
    final y2 = (d.boundingBox.bottom * image.height).round();

    img.drawRect(
      image,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
      color: color,
      thickness: thickness,
    );

    final label = '${d.label} ${(d.confidence * 100).round()}%';
    final font = longest > 1400
        ? img.arial48
        : (longest > 700 ? img.arial24 : img.arial14);
    final textHeight = font.lineHeight + 4;
    final textWidth = label.length * (font.lineHeight * 0.6).round() + 8;
    final top = (y1 - textHeight) < 0 ? y1 : y1 - textHeight;

    img.fillRect(
      image,
      x1: x1,
      y1: top,
      x2: x1 + textWidth,
      y2: top + textHeight,
      color: color,
    );
    img.drawString(
      image,
      label,
      font: font,
      x: x1 + 4,
      y: top + 2,
      color: img.ColorRgb8(255, 255, 255),
    );
  }
  return image;
}

/// PNG bytes of [source] with the detections drawn on it.
Uint8List annotatedPng(img.Image source, List<DetectedObject> detections) {
  return Uint8List.fromList(img.encodePng(drawDetections(source, detections)));
}

/// Input for [renderAnnotatedFromBytes]; sendable to a `compute()` isolate.
class AnnotateRequest {
  const AnnotateRequest({required this.imageBytes, required this.detections});

  final Uint8List imageBytes;
  final List<DetectedObject> detections;
}

/// Decodes [AnnotateRequest.imageBytes] (honouring EXIF orientation, like the
/// detector did), draws the detections and returns PNG bytes, or null when the
/// bytes are not a decodable image. Top-level so it can run in `compute()`;
/// decoding and encoding a full-size photo is too slow for the UI thread.
Uint8List? renderAnnotatedFromBytes(AnnotateRequest request) {
  final image = decodeUpright(request.imageBytes);
  if (image == null) return null;
  return annotatedPng(image, request.detections);
}
