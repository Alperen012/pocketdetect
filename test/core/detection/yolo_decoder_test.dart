import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/detection/letterbox.dart';
import 'package:mobile_yolo/core/detection/yolo_decoder.dart';

/// Builds a `[4 + classes][anchors]` output from per-anchor rows of
/// `[cx, cy, w, h, ...scores]`.
List<List<double>> outputFrom(List<List<double>> anchors) {
  final channels = anchors.first.length;
  return List<List<double>>.generate(
    channels,
    (c) => anchors.map((a) => a[c]).toList(),
  );
}

const _square = LetterboxParams(
  inputSize: 640,
  sourceWidth: 640,
  sourceHeight: 640,
  scaledWidth: 640,
  scaledHeight: 640,
  padX: 0,
  padY: 0,
);

DecodeRequest request(
  List<List<double>> anchors, {
  LetterboxParams letterbox = _square,
  double confidence = 0.5,
  List<String> labels = const <String>['cat', 'dog'],
  List<String> selected = const <String>['cat', 'dog'],
  bool filter = false,
}) {
  return DecodeRequest(
    output: outputFrom(anchors),
    letterbox: letterbox,
    confidence: confidence,
    labels: labels,
    selectedLabels: selected,
    filterBySelected: filter,
  );
}

void main() {
  group('decodeYolo', () {
    test('empty output yields nothing', () {
      final result = decodeYolo(
        const DecodeRequest(
          output: <List<double>>[],
          letterbox: _square,
          confidence: 0.5,
          labels: <String>['cat'],
          selectedLabels: <String>['cat'],
          filterBySelected: false,
        ),
      );
      expect(result, isEmpty);
    });

    test('decodes the best class and a square-input box unchanged', () {
      final result = decodeYolo(
        request(<List<double>>[
          <double>[0.5, 0.5, 0.2, 0.4, 0.1, 0.9],
        ]),
      );

      expect(result, hasLength(1));
      final d = result.single;
      expect(d.label, 'dog');
      expect(d.score, 0.9);
      expect(d.left, closeTo(0.4, 1e-9));
      expect(d.top, closeTo(0.3, 1e-9));
      expect(d.width, closeTo(0.2, 1e-9));
      expect(d.height, closeTo(0.4, 1e-9));
    });

    test('maps boxes back through vertical letterbox padding', () {
      // 1280x640 source in a 640 input: 160px padding top and bottom.
      const lb = LetterboxParams(
        inputSize: 640,
        sourceWidth: 1280,
        sourceHeight: 640,
        scaledWidth: 640,
        scaledHeight: 320,
        padX: 0,
        padY: 160,
      );
      final result = decodeYolo(
        request(<List<double>>[
          <double>[0.5, 0.5, 0.5, 0.25, 0.9, 0.0],
        ], letterbox: lb),
      );

      final d = result.single;
      expect(d.left, closeTo(0.25, 1e-9));
      expect(d.top, closeTo(0.25, 1e-9));
      expect(d.width, closeTo(0.5, 1e-9));
      expect(d.height, closeTo(0.5, 1e-9));
    });

    test('maps boxes back through horizontal letterbox padding', () {
      const lb = LetterboxParams(
        inputSize: 640,
        sourceWidth: 480,
        sourceHeight: 960,
        scaledWidth: 320,
        scaledHeight: 640,
        padX: 160,
        padY: 0,
      );
      final result = decodeYolo(
        request(<List<double>>[
          <double>[0.5, 0.5, 0.25, 0.5, 0.9, 0.0],
        ], letterbox: lb),
      );

      final d = result.single;
      expect(d.left, closeTo(0.25, 1e-9));
      expect(d.top, closeTo(0.25, 1e-9));
      expect(d.width, closeTo(0.5, 1e-9));
      expect(d.height, closeTo(0.5, 1e-9));
    });

    test('clamps boxes that spill outside the image', () {
      final result = decodeYolo(
        request(<List<double>>[
          <double>[0.05, 0.95, 0.4, 0.4, 0.9, 0.0],
        ]),
      );

      final d = result.single;
      expect(d.left, 0.0);
      expect(d.top, closeTo(0.75, 1e-9));
      expect(d.top + d.height, lessThanOrEqualTo(1.0));
    });

    test('drops detections below the confidence threshold', () {
      final result = decodeYolo(
        request(<List<double>>[
          <double>[0.5, 0.5, 0.1, 0.1, 0.49, 0.2],
          <double>[0.5, 0.5, 0.1, 0.1, 0.5, 0.2],
        ]),
      );
      expect(result, hasLength(1));
      expect(result.single.score, 0.5);
    });

    test('ignores class channels beyond the label list', () {
      final result = decodeYolo(
        request(<List<double>>[
          <double>[0.5, 0.5, 0.1, 0.1, 0.1, 0.1, 0.99],
        ]),
      );
      expect(result, isEmpty);
    });

    test('applies the selected-label filter only when enabled', () {
      final anchors = <List<double>>[
        <double>[0.5, 0.5, 0.1, 0.1, 0.9, 0.0],
        <double>[0.2, 0.2, 0.1, 0.1, 0.0, 0.8],
      ];

      final filtered = decodeYolo(
        request(anchors, selected: const <String>['dog'], filter: true),
      );
      expect(filtered.map((d) => d.label), <String>['dog']);

      final unfiltered = decodeYolo(
        request(anchors, selected: const <String>['dog'], filter: false),
      );
      expect(unfiltered.map((d) => d.label), <String>['cat', 'dog']);
    });

    test('sorts by score descending', () {
      final result = decodeYolo(
        request(<List<double>>[
          <double>[0.2, 0.2, 0.1, 0.1, 0.6, 0.0],
          <double>[0.5, 0.5, 0.1, 0.1, 0.9, 0.0],
          <double>[0.8, 0.8, 0.1, 0.1, 0.0, 0.7],
        ]),
      );
      expect(result.map((d) => d.score), <double>[0.9, 0.7, 0.6]);
    });
  });
}
