import 'dart:ui' show Rect;

import '../models/detected_object.dart';

/// Intersection-over-union of two rectangles; 0 when they do not overlap.
double iou(Rect a, Rect b) {
  final intersection = a.intersect(b);
  if (intersection.isEmpty) {
    return 0.0;
  }
  final intersectionArea = intersection.width * intersection.height;
  final unionArea =
      (a.width * a.height) + (b.width * b.height) - intersectionArea;
  if (unionArea <= 0) {
    return 0.0;
  }
  return intersectionArea / unionArea;
}

/// Greedy class-agnostic non-maximum suppression. Keeps the highest
/// confidence box, drops any remaining box with IoU above [iouThreshold],
/// and stops after [maxDetections] results.
List<DetectedObject> nonMaxSuppression(
  List<DetectedObject> detections,
  double iouThreshold,
  int maxDetections,
) {
  final results = <DetectedObject>[];
  final sorted = List<DetectedObject>.from(detections)
    ..sort((a, b) => b.confidence.compareTo(a.confidence));

  while (sorted.isNotEmpty && results.length < maxDetections) {
    final current = sorted.removeAt(0);
    results.add(current);
    sorted.removeWhere(
      (candidate) => iou(current.boundingBox, candidate.boundingBox) > iouThreshold,
    );
  }
  return results;
}
