import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../detection/interpreter_factory.dart';

/// Summary of a series of timings, in milliseconds.
@immutable
class TimingStats {
  const TimingStats({
    required this.count,
    required this.meanMs,
    required this.medianMs,
    required this.p90Ms,
    required this.minMs,
    required this.maxMs,
  });

  /// Throws [ArgumentError] on an empty list.
  factory TimingStats.fromSamples(List<double> samplesMs) {
    if (samplesMs.isEmpty) {
      throw ArgumentError('Need at least one sample');
    }
    final sorted = List<double>.of(samplesMs)..sort();
    final n = sorted.length;
    final mid = n ~/ 2;
    return TimingStats(
      count: n,
      meanMs: sorted.reduce((a, b) => a + b) / n,
      medianMs: n.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2,
      // Nearest-rank percentile.
      p90Ms: sorted[math.max(0, (0.9 * n).ceil() - 1)],
      minMs: sorted.first,
      maxMs: sorted.last,
    );
  }

  final int count;
  final double meanMs;
  final double medianMs;
  final double p90Ms;
  final double minMs;
  final double maxMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'count': count,
        'meanMs': _round(meanMs),
        'medianMs': _round(medianMs),
        'p90Ms': _round(p90Ms),
        'minMs': _round(minMs),
        'maxMs': _round(maxMs),
      };
}

double _round(double v) => (v * 100).roundToDouble() / 100;

/// One accelerator's benchmark outcome.
@immutable
class DelegateBenchmark {
  const DelegateBenchmark({
    required this.requested,
    required this.loadMs,
    this.actual,
    this.wall,
    this.native,
    this.error,
    this.fallbackReasons = const <DelegateKind, String>{},
  });

  /// What the user asked for.
  final AcceleratorPreference requested;

  /// What actually ran; differs from [requested] when it fell back.
  final DelegateKind? actual;

  /// Time to create the interpreter.
  final double loadMs;

  /// Time around `runInference` as seen from Dart.
  final TimingStats? wall;

  /// Time spent inside TFLite, as reported by the interpreter.
  final TimingStats? native;

  /// Set when even loading failed.
  final String? error;

  /// Delegates tried first that could not load, with the reason.
  final Map<DelegateKind, String> fallbackReasons;

  bool get succeeded => error == null && wall != null;

  /// True when the requested accelerator was not the one that ran.
  bool get fellBack {
    final a = actual;
    if (a == null) return false;
    return switch (requested) {
      AcceleratorPreference.auto => false,
      AcceleratorPreference.cpu => a != DelegateKind.cpu,
      AcceleratorPreference.gpu => a != DelegateKind.gpu,
      AcceleratorPreference.nnapi => a != DelegateKind.nnapi,
    };
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'requested': requested.name,
        'actual': actual?.name,
        'fellBack': fellBack,
        'loadMs': _round(loadMs),
        'wall': wall?.toJson(),
        'native': native?.toJson(),
        'error': error,
        'fallbackReasons': <String, String>{
          for (final e in fallbackReasons.entries) e.key.name: e.value,
        },
      };
}

/// A full benchmark of one model on this device.
@immutable
class BenchmarkReport {
  const BenchmarkReport({
    required this.modelName,
    required this.inputWidth,
    required this.inputHeight,
    required this.quantType,
    required this.warmupRuns,
    required this.measuredRuns,
    required this.createdAt,
    required this.results,
    this.device = const <String, String>{},
  });

  final String modelName;
  final int inputWidth;
  final int inputHeight;
  final String quantType;
  final int warmupRuns;
  final int measuredRuns;
  final DateTime createdAt;
  final List<DelegateBenchmark> results;
  final Map<String, String> device;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'model': <String, dynamic>{
          'name': modelName,
          'input': '${inputWidth}x$inputHeight',
          'quantization': quantType,
        },
        'device': device,
        'warmupRuns': warmupRuns,
        'measuredRuns': measuredRuns,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
      };

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  /// Plain-text summary suitable for pasting into an issue or chat.
  String toText() {
    final b = StringBuffer()
      ..writeln('$modelName  ${inputWidth}x$inputHeight  $quantType');
    if (device.isNotEmpty) {
      b.writeln(device.entries.map((e) => '${e.key}: ${e.value}').join(' | '));
    }
    b.writeln('warmup $warmupRuns, measured $measuredRuns runs (ms)');
    for (final r in results) {
      final label = r.requested.name.toUpperCase();
      if (!r.succeeded) {
        b.writeln('$label: failed (${r.error ?? 'no result'})');
        continue;
      }
      final w = r.wall!;
      final n = r.native;
      final ran = r.fellBack ? ' (ran on ${r.actual!.name.toUpperCase()})' : '';
      b.writeln(
        '$label$ran: median ${w.medianMs.toStringAsFixed(1)}, '
        'mean ${w.meanMs.toStringAsFixed(1)}, '
        'p90 ${w.p90Ms.toStringAsFixed(1)}, '
        'min ${w.minMs.toStringAsFixed(1)}'
        '${n == null ? '' : ', native median ${n.medianMs.toStringAsFixed(1)}'}'
        ', load ${r.loadMs.toStringAsFixed(0)}',
      );
    }
    return b.toString().trimRight();
  }
}
