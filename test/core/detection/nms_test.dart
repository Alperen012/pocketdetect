import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/detection/nms.dart';
import 'package:mobile_yolo/core/models/detected_object.dart';

DetectedObject det(String label, double conf, Rect box) =>
    DetectedObject(label: label, confidence: conf, boundingBox: box);

void main() {
  group('iou', () {
    test('identical boxes have IoU 1', () {
      const r = Rect.fromLTWH(0, 0, 10, 10);
      expect(iou(r, r), closeTo(1.0, 1e-9));
    });

    test('disjoint boxes have IoU 0', () {
      expect(
        iou(const Rect.fromLTWH(0, 0, 10, 10), const Rect.fromLTWH(20, 20, 5, 5)),
        0.0,
      );
    });

    test('touching edges have IoU 0', () {
      expect(
        iou(const Rect.fromLTWH(0, 0, 10, 10), const Rect.fromLTWH(10, 0, 10, 10)),
        0.0,
      );
    });

    test('half-overlapping boxes have IoU 1/3', () {
      expect(
        iou(const Rect.fromLTWH(0, 0, 10, 10), const Rect.fromLTWH(5, 0, 10, 10)),
        closeTo(50 / 150, 1e-9),
      );
    });

    test('zero-area boxes have IoU 0', () {
      const r = Rect.fromLTWH(1, 1, 0, 0);
      expect(iou(r, r), 0.0);
    });
  });

  group('nonMaxSuppression', () {
    test('keeps the highest-confidence box of an overlapping pair', () {
      final result = nonMaxSuppression(
        <DetectedObject>[
          det('a', 0.6, const Rect.fromLTWH(0, 0, 10, 10)),
          det('b', 0.9, const Rect.fromLTWH(1, 1, 10, 10)),
        ],
        0.5,
        10,
      );
      expect(result.map((d) => d.label), <String>['b']);
    });

    test('keeps boxes whose IoU is at or below the threshold', () {
      final result = nonMaxSuppression(
        <DetectedObject>[
          det('a', 0.9, const Rect.fromLTWH(0, 0, 10, 10)),
          det('b', 0.8, const Rect.fromLTWH(5, 0, 10, 10)),
        ],
        1 / 3,
        10,
      );
      expect(result.map((d) => d.label), <String>['a', 'b']);
    });

    test('is class agnostic', () {
      final result = nonMaxSuppression(
        <DetectedObject>[
          det('cat', 0.9, const Rect.fromLTWH(0, 0, 10, 10)),
          det('dog', 0.8, const Rect.fromLTWH(0, 0, 10, 10)),
        ],
        0.5,
        10,
      );
      expect(result.map((d) => d.label), <String>['cat']);
    });

    test('stops at maxDetections', () {
      final result = nonMaxSuppression(
        <DetectedObject>[
          det('a', 0.9, const Rect.fromLTWH(0, 0, 1, 1)),
          det('b', 0.8, const Rect.fromLTWH(10, 0, 1, 1)),
          det('c', 0.7, const Rect.fromLTWH(20, 0, 1, 1)),
        ],
        0.5,
        2,
      );
      expect(result.map((d) => d.label), <String>['a', 'b']);
    });

    test('does not mutate the input list', () {
      final input = <DetectedObject>[
        det('a', 0.5, const Rect.fromLTWH(0, 0, 1, 1)),
        det('b', 0.9, const Rect.fromLTWH(10, 0, 1, 1)),
      ];
      nonMaxSuppression(input, 0.5, 10);
      expect(input.map((d) => d.label), <String>['a', 'b']);
    });

    test('empty input yields empty output', () {
      expect(nonMaxSuppression(const <DetectedObject>[], 0.5, 10), isEmpty);
    });
  });
}
