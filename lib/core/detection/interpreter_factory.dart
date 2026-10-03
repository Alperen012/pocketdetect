import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';

/// Hardware path a TFLite interpreter runs on.
enum DelegateKind { nnapi, gpu, cpu }

/// User-facing accelerator choice. [auto] tries the fastest options first.
enum AcceleratorPreference { auto, cpu, gpu, nnapi }

/// Delegates to try, in order, for [preference]. CPU is always the last
/// resort so a model never fails to load just because an accelerator is
/// unsupported on the device.
List<DelegateKind> delegateAttemptOrder(AcceleratorPreference preference) {
  return switch (preference) {
    AcceleratorPreference.auto => const <DelegateKind>[
      DelegateKind.nnapi,
      DelegateKind.gpu,
      DelegateKind.cpu,
    ],
    AcceleratorPreference.cpu => const <DelegateKind>[DelegateKind.cpu],
    AcceleratorPreference.gpu => const <DelegateKind>[
      DelegateKind.gpu,
      DelegateKind.cpu,
    ],
    AcceleratorPreference.nnapi => const <DelegateKind>[
      DelegateKind.nnapi,
      DelegateKind.cpu,
    ],
  };
}

/// Where the model bytes come from: exactly one of [filePath] / [assetPath].
class ModelSource {
  const ModelSource.file(String path) : filePath = path, assetPath = null;
  const ModelSource.asset(String path) : filePath = null, assetPath = path;

  final String? filePath;
  final String? assetPath;
}

/// Outcome of [createInterpreter]: the interpreter, which delegate ended up
/// running it, and why the earlier attempts failed (so the UI and the
/// benchmark can say "GPU unsupported" instead of silently falling back).
class InterpreterLoadResult {
  const InterpreterLoadResult({
    required this.interpreter,
    required this.delegate,
    required this.failures,
  });

  final Interpreter interpreter;
  final DelegateKind delegate;
  final Map<DelegateKind, Object> failures;
}

/// Creates an interpreter for [source], trying delegates per [preference].
/// Throws only if even the CPU attempt fails.
Future<InterpreterLoadResult> createInterpreter(
  ModelSource source, {
  AcceleratorPreference preference = AcceleratorPreference.auto,
}) async {
  final failures = <DelegateKind, Object>{};
  Object? lastError;

  for (final kind in delegateAttemptOrder(preference)) {
    GpuDelegateV2? gpu;
    try {
      final options = InterpreterOptions();
      switch (kind) {
        case DelegateKind.nnapi:
          options.useNnApiForAndroid = true;
        case DelegateKind.gpu:
          gpu = GpuDelegateV2();
          options.addDelegate(gpu);
        case DelegateKind.cpu:
          break;
      }
      final interpreter = await _open(source, options);
      return InterpreterLoadResult(
        interpreter: interpreter,
        delegate: kind,
        failures: failures,
      );
    } catch (e) {
      gpu?.delete();
      failures[kind] = e;
      lastError = e;
    }
  }

  throw StateError('Could not load model on any delegate: $lastError');
}

Future<Interpreter> _open(ModelSource source, InterpreterOptions options) {
  final file = source.filePath;
  if (file != null) {
    return Future<Interpreter>.value(
      Interpreter.fromFile(File(file), options: options),
    );
  }
  return Interpreter.fromAsset(source.assetPath!, options: options);
}
