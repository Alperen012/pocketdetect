import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/benchmark/benchmark_report.dart';
import 'package:mobile_yolo/core/detection/interpreter_factory.dart';
import 'package:mobile_yolo/core/models/installed_model.dart';
import 'package:mobile_yolo/features/models/benchmark_screen.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';

BenchmarkReport fakeReport() => BenchmarkReport(
  modelName: 'YOLO26 Nano (INT8)',
  inputWidth: 832,
  inputHeight: 832,
  quantType: 'INT8',
  warmupRuns: 3,
  measuredRuns: 10,
  createdAt: DateTime.utc(2026),
  results: <DelegateBenchmark>[
    DelegateBenchmark(
      requested: AcceleratorPreference.cpu,
      actual: DelegateKind.cpu,
      loadMs: 100,
      wall: TimingStats.fromSamples(<double>[40, 42, 47]),
    ),
    DelegateBenchmark(
      requested: AcceleratorPreference.gpu,
      actual: DelegateKind.cpu,
      loadMs: 250,
      wall: TimingStats.fromSamples(<double>[41, 43, 45]),
    ),
    const DelegateBenchmark(
      requested: AcceleratorPreference.nnapi,
      loadMs: 5,
      error: 'not supported',
    ),
  ],
);

Widget app(BenchmarkRunner runner) {
  return MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    home: BenchmarkScreen(model: InstalledModel.builtIn, runner: runner),
  );
}

void main() {
  testWidgets('shows the model and a run button before any run', (
    tester,
  ) async {
    await tester.pumpWidget(
      app((m, {onProgress, isCancelled}) async => fakeReport()),
    );

    expect(find.text('YOLO26 Nano (INT8)'), findsOneWidget);
    expect(find.text('Run benchmark'), findsOneWidget);
    expect(find.text('Share summary'), findsNothing);
  });

  testWidgets('renders each accelerator, fallbacks and failures', (
    tester,
  ) async {
    // Tall enough that the lazily built list shows every result card.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app((m, {onProgress, isCancelled}) async => fakeReport()),
    );

    await tester.tap(find.text('Run benchmark'));
    await tester.pumpAndSettle();

    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('42.0 ms'), findsOneWidget); // CPU median
    expect(find.text('47.0 ms'), findsOneWidget); // CPU p90
    expect(find.text('Ran on CPU instead'), findsOneWidget); // GPU fell back
    expect(find.text('Failed: not supported'), findsOneWidget); // NNAPI
    expect(find.text('Run again'), findsOneWidget);
    expect(find.text('Share summary'), findsOneWidget);
  });

  testWidgets('shows progress while running and can be cancelled', (
    tester,
  ) async {
    final gate = Completer<BenchmarkReport>();
    var cancelled = false;
    await tester.pumpWidget(
      app((m, {onProgress, isCancelled}) {
        onProgress?.call('CPU · run', 0.5);
        // Poll the cancel flag the way the real runner does.
        Timer.periodic(const Duration(milliseconds: 10), (t) {
          if (isCancelled?.call() ?? false) {
            cancelled = true;
            t.cancel();
            gate.complete(fakeReport());
          }
        });
        return gate.future;
      }),
    );

    await tester.tap(find.text('Run benchmark'));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('CPU · run'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(cancelled, isTrue);
    expect(find.text('Run again'), findsOneWidget);
  });

  testWidgets('a runner that throws shows the error and allows a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      app((m, {onProgress, isCancelled}) async {
        throw StateError('no interpreter');
      }),
    );

    await tester.tap(find.text('Run benchmark'));
    await tester.pumpAndSettle();

    expect(find.textContaining('no interpreter'), findsOneWidget);
    expect(find.text('Run benchmark'), findsOneWidget);
  });
}
