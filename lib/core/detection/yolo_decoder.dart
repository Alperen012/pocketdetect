import 'package:flutter/foundation.dart';

import 'letterbox.dart';

/// A decoded detection in plain, isolate-sendable form. Coordinates are
/// normalized to the original (un-letterboxed) image.
@immutable
class RawDetection {
  const RawDetection({
    required this.label,
    required this.score,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String label;
  final double score;
  final double left;
  final double top;
  final double width;
  final double height;
}

/// Input for [decodeYolo]. Must stay sendable to a `compute()` isolate.
@immutable
class DecodeRequest {
  const DecodeRequest({
    required this.output,
    required this.letterbox,
    required this.confidence,
    required this.labels,
    required this.selectedLabels,
    required this.filterBySelected,
  });

  /// Dequantized model output laid out as `[4 + classes][anchors]` with
  /// normalized `cx, cy, w, h` rows followed by one score row per class.
  final List<List<double>> output;
  final LetterboxParams letterbox;
  final double confidence;
  final List<String> labels;
  final List<String> selectedLabels;
  final bool filterBySelected;
}

/// Decodes a raw YOLO output tensor into detections, applying the confidence
/// threshold and optional label filter, and mapping boxes back through the
/// letterbox. Sorted by score, highest first. Top-level so it can run in
/// `compute()`.
List<RawDetection> decodeYolo(DecodeRequest request) {
  final output = request.output;
  if (output.isEmpty) {
    return const <RawDetection>[];
  }

  final channels = output.length;
  final count = output[0].length;
  final selected = request.selectedLabels.toSet();
  final lb = request.letterbox;

  // Model coordinates are normalized to the full letterboxed square. Express
  // the padding and scaled image area in the same space.
  final padXN = lb.padX / lb.inputSize;
  final padYN = lb.padY / lb.inputSize;
  final scaledWN = lb.scaledWidth / lb.inputSize;
  final scaledHN = lb.scaledHeight / lb.inputSize;

  final results = <RawDetection>[];
  for (var i = 0; i < count; i++) {
    var bestScore = 0.0;
    var bestClass = -1;
    for (var c = 4; c < channels; c++) {
      final score = output[c][i];
      if (score > bestScore) {
        bestScore = score;
        bestClass = c - 4;
      }
    }

    if (bestScore < request.confidence ||
        bestClass < 0 ||
        bestClass >= request.labels.length) {
      continue;
    }

    final label = request.labels[bestClass];
    if (request.filterBySelected && !selected.contains(label)) {
      continue;
    }

    final cx = output[0][i];
    final cy = output[1][i];
    final w = output[2][i];
    final h = output[3][i];

    final left = ((cx - w / 2 - padXN) / scaledWN).clamp(0.0, 1.0);
    final top = ((cy - h / 2 - padYN) / scaledHN).clamp(0.0, 1.0);
    final width = (w / scaledWN).clamp(0.0, 1.0 - left);
    final height = (h / scaledHN).clamp(0.0, 1.0 - top);

    results.add(RawDetection(
      label: label,
      score: bestScore,
      left: left,
      top: top,
      width: width,
      height: height,
    ));
  }

  results.sort((a, b) => b.score.compareTo(a.score));
  return results;
}
