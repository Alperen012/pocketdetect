import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/benchmark/benchmark_report.dart';
import 'package:mobile_yolo/core/detection/interpreter_factory.dart';

void main() {
  group('TimingStats.fromSamples', () {
    test('computes mean, median, p90, min and max', () {
      final s = TimingStats.fromSamples(<double>[
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        90,
        100,
      ]);

      expect(s.count, 10);
      expect(s.meanMs, 55);
      expect(s.medianMs, 55); // even count: mean of the middle two
      expect(s.p90Ms, 90); // nearest rank: ceil(0.9 * 10) = 9th value
      expect(s.minMs, 10);
      expect(s.maxMs, 100);
    });

    test('median of an odd count is the middle value', () {
      final s = TimingStats.fromSamples(<double>[5, 1, 9]);

      expect(s.medianMs, 5);
      expect(s.p90Ms, 9);
    });

    test('does not depend on input order and does not mutate it', () {
      final input = <double>[30, 10, 20];
      final s = TimingStats.fromSamples(input);

      expect(s.minMs, 10);
      expect(s.maxMs, 30);
      expect(input, <double>[30, 10, 20]);
    });

    test('a single sample fills every field', () {
      final s = TimingStats.fromSamples(<double>[42]);

      expect(<double>[
        s.meanMs,
        s.medianMs,
        s.p90Ms,
        s.minMs,
        s.maxMs,
      ], everyElement(42));
    });

    test('rejects an empty list', () {
      expect(() => TimingStats.fromSamples(<double>[]), throwsArgumentError);
    });
  });

  group('DelegateBenchmark.fellBack', () {
    TimingStats stats() => TimingStats.fromSamples(<double>[1]);

    test('is true when a requested accelerator ended up on the CPU', () {
      final r = DelegateBenchmark(
        requested: AcceleratorPreference.gpu,
        actual: DelegateKind.cpu,
        loadMs: 1,
        wall: stats(),
      );
      expect(r.fellBack, isTrue);
    });

    test('is false when the request was honoured, or auto', () {
      expect(
        DelegateBenchmark(
          requested: AcceleratorPreference.gpu,
          actual: DelegateKind.gpu,
          loadMs: 1,
          wall: stats(),
        ).fellBack,
        isFalse,
      );
      expect(
        DelegateBenchmark(
          requested: AcceleratorPreference.auto,
          actual: DelegateKind.nnapi,
          loadMs: 1,
          wall: stats(),
        ).fellBack,
        isFalse,
      );
    });
  });

  group('BenchmarkReport', () {
    BenchmarkReport report() => BenchmarkReport(
      modelName: 'YOLO26 Nano (INT8)',
      inputWidth: 832,
      inputHeight: 832,
      quantType: 'INT8',
      warmupRuns: 3,
      measuredRuns: 10,
      createdAt: DateTime.utc(2026, 5, 1),
      device: const <String, String>{'model': 'Pixel 8', 'android': '15'},
      results: <DelegateBenchmark>[
        DelegateBenchmark(
          requested: AcceleratorPreference.cpu,
          actual: DelegateKind.cpu,
          loadMs: 120,
          wall: TimingStats.fromSamples(<double>[40, 42, 44]),
          native: TimingStats.fromSamples(<double>[38, 40, 42]),
        ),
        DelegateBenchmark(
          requested: AcceleratorPreference.gpu,
          actual: DelegateKind.cpu,
          loadMs: 300,
          wall: TimingStats.fromSamples(<double>[41, 43, 45]),
          fallbackReasons: const <DelegateKind, String>{
            DelegateKind.gpu: 'unsupported op',
          },
        ),
        const DelegateBenchmark(
          requested: AcceleratorPreference.nnapi,
          loadMs: 5,
          error: 'boom',
        ),
      ],
    );

    test('JSON round-trips the key fields', () {
      final json = jsonDecode(report().toJsonString()) as Map<String, dynamic>;

      expect(json['model']['input'], '832x832');
      expect(json['device']['model'], 'Pixel 8');
      expect(json['measuredRuns'], 10);
      final results = json['results'] as List<dynamic>;
      expect(results, hasLength(3));
      expect(results[0]['wall']['medianMs'], 42);
      expect(results[1]['fellBack'], isTrue);
      expect(results[1]['fallbackReasons']['gpu'], 'unsupported op');
      expect(results[2]['error'], 'boom');
      expect(results[2]['wall'], isNull);
    });

    test('text summary names each accelerator, fallbacks and failures', () {
      final text = report().toText();

      expect(text, contains('YOLO26 Nano (INT8)  832x832  INT8'));
      expect(text, contains('model: Pixel 8 | android: 15'));
      expect(text, contains('CPU: median 42.0'));
      expect(text, contains('native median 40.0'));
      expect(text, contains('GPU (ran on CPU)'));
      expect(text, contains('NNAPI: failed (boom)'));
    });
  });
}
