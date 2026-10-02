import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../detection/interpreter_factory.dart';
import '../models/installed_model.dart';
import 'benchmark_report.dart';

/// Progress callback: a short stage name and overall progress `0..1`.
typedef BenchmarkProgress = void Function(String stage, double progress);

/// Times a model on this device, one accelerator at a time.
///
/// Uses an all-zero input of the model's real input size, so the numbers
/// reflect the network, not image decoding or pre/post-processing. Inference
/// runs on the calling isolate (the interpreter holds native resources), so
/// the UI may stutter during a run; frames are yielded between iterations.
class ModelBenchmark {
  const ModelBenchmark._();

  static const List<AcceleratorPreference> defaultAccelerators =
      <AcceleratorPreference>[
    AcceleratorPreference.cpu,
    AcceleratorPreference.gpu,
    AcceleratorPreference.nnapi,
  ];

  static Future<BenchmarkReport> run(
    InstalledModel model, {
    List<AcceleratorPreference> accelerators = defaultAccelerators,
    int warmupRuns = 3,
    int measuredRuns = 20,
    BenchmarkProgress? onProgress,
    bool Function()? isCancelled,
  }) async {
    final results = <DelegateBenchmark>[];
    final stepsPerAccelerator = 1 + warmupRuns + measuredRuns;
    final totalSteps = accelerators.length * stepsPerAccelerator;
    var done = 0;
    void step(String stage) {
      done++;
      onProgress?.call(stage, done / totalSteps);
    }

    for (final pref in accelerators) {
      if (isCancelled?.call() ?? false) break;
      final label = pref.name.toUpperCase();
      results.add(await _benchmarkOne(
        model,
        pref,
        warmupRuns: warmupRuns,
        measuredRuns: measuredRuns,
        onStep: (phase) => step('$label · $phase'),
        isCancelled: isCancelled,
      ));
      // Steps skipped by a load failure or cancel still count as progress.
      done = results.length * stepsPerAccelerator;
    }

    return BenchmarkReport(
      modelName: model.name,
      inputWidth: model.inputWidth,
      inputHeight: model.inputHeight,
      quantType: model.quantType,
      warmupRuns: warmupRuns,
      measuredRuns: measuredRuns,
      createdAt: DateTime.now(),
      results: results,
      device: await deviceDescription(),
    );
  }

  static Future<DelegateBenchmark> _benchmarkOne(
    InstalledModel model,
    AcceleratorPreference pref, {
    required int warmupRuns,
    required int measuredRuns,
    required void Function(String phase) onStep,
    bool Function()? isCancelled,
  }) async {
    final source = model.filePath != null
        ? ModelSource.file(model.filePath!)
        : ModelSource.asset(model.assetPath!);

    final loadWatch = Stopwatch()..start();
    final InterpreterLoadResult loaded;
    try {
      loaded = await createInterpreter(source, preference: pref);
    } catch (e) {
      return DelegateBenchmark(
        requested: pref,
        loadMs: loadWatch.elapsedMicroseconds / 1000,
        error: e.toString(),
      );
    }
    loadWatch.stop();
    onStep('load');

    final interpreter = loaded.interpreter;
    try {
      final input = Uint8List(interpreter.getInputTensor(0).numBytes());

      for (var i = 0; i < warmupRuns; i++) {
        interpreter.runInference(<Object>[input]);
        onStep('warm-up');
        await Future<void>.delayed(Duration.zero);
      }

      final wall = <double>[];
      final native = <double>[];
      final watch = Stopwatch();
      for (var i = 0; i < measuredRuns; i++) {
        if (isCancelled?.call() ?? false) break;
        watch
          ..reset()
          ..start();
        interpreter.runInference(<Object>[input]);
        watch.stop();
        wall.add(watch.elapsedMicroseconds / 1000);
        native.add(interpreter.lastNativeInferenceDurationMicroSeconds / 1000);
        onStep('run');
        await Future<void>.delayed(Duration.zero);
      }

      return DelegateBenchmark(
        requested: pref,
        actual: loaded.delegate,
        loadMs: loadWatch.elapsedMicroseconds / 1000,
        wall: wall.isEmpty ? null : TimingStats.fromSamples(wall),
        native: native.isEmpty || native.every((v) => v == 0)
            ? null
            : TimingStats.fromSamples(native),
        error: wall.isEmpty ? 'cancelled' : null,
        fallbackReasons: <DelegateKind, String>{
          for (final e in loaded.failures.entries) e.key: e.value.toString(),
        },
      );
    } catch (e) {
      // e.g. a GPU delegate that loads but cannot run this model.
      return DelegateBenchmark(
        requested: pref,
        actual: loaded.delegate,
        loadMs: loadWatch.elapsedMicroseconds / 1000,
        error: e.toString(),
        fallbackReasons: <DelegateKind, String>{
          for (final e in loaded.failures.entries) e.key: e.value.toString(),
        },
      );
    } finally {
      interpreter.close();
    }
  }

  /// Short, non-identifying description of this device for the report.
  static Future<Map<String, String>> deviceDescription() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        return <String, String>{
          'device': '${a.manufacturer} ${a.model}',
          'android': a.version.release,
          'sdk': '${a.version.sdkInt}',
          'abi': a.supportedAbis.isEmpty ? '' : a.supportedAbis.first,
        };
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        return <String, String>{
          'device': i.utsname.machine,
          'ios': i.systemVersion,
        };
      }
    } catch (e) {
      debugPrint('Device info unavailable: $e');
    }
    return <String, String>{'platform': Platform.operatingSystem};
  }
}
