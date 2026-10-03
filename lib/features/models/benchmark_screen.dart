import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/benchmark/benchmark_report.dart';
import '../../core/benchmark/model_benchmark.dart';
import '../../core/detection/interpreter_factory.dart';
import '../../core/export/share_service.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/installed_model.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Runs a benchmark; injectable so the screen can be tested without TFLite.
typedef BenchmarkRunner =
    Future<BenchmarkReport> Function(
      InstalledModel model, {
      BenchmarkProgress? onProgress,
      bool Function()? isCancelled,
    });

Future<BenchmarkReport> _defaultRunner(
  InstalledModel model, {
  BenchmarkProgress? onProgress,
  bool Function()? isCancelled,
}) {
  return ModelBenchmark.run(
    model,
    onProgress: onProgress,
    isCancelled: isCancelled,
  );
}

/// Times one model on every accelerator and lets the user share the result.
class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({
    super.key,
    required this.model,
    this.runner = _defaultRunner,
    this.share = const ShareService(),
  });

  final InstalledModel model;
  final BenchmarkRunner runner;
  final ShareService share;

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  bool _running = false;
  bool _cancelRequested = false;
  double _progress = 0;
  String _stage = '';
  BenchmarkReport? _report;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _cancelRequested = false;
      _progress = 0;
      _stage = '';
      _report = null;
      _error = null;
    });

    try {
      final report = await widget.runner(
        widget.model,
        onProgress: (stage, progress) {
          if (!mounted) return;
          setState(() {
            _stage = stage;
            _progress = progress;
          });
        },
        isCancelled: () => _cancelRequested,
      );
      if (!mounted) return;
      setState(() => _report = report);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _share(Future<void> Function() action) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final model = widget.model;
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.benchmarkTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.memory, color: AppColors.accent),
                title: Text(model.name),
                subtitle: Text(
                  '${model.inputWidth}×${model.inputHeight} · ${model.quantType}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.benchmarkIntro,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (_running) ...<Widget>[
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              const SizedBox(height: 8),
              Text(
                '${l10n.benchmarkRunning} $_stage',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _cancelRequested
                    ? null
                    : () => setState(() => _cancelRequested = true),
                child: Text(l10n.cancel),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _run,
                icon: const Icon(Icons.speed),
                label: Text(
                  report == null ? l10n.benchmarkRun : l10n.benchmarkRunAgain,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                l10n.benchmarkFailed(_error!),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            if (report != null) ...<Widget>[
              const SizedBox(height: 20),
              for (final result in report.results) ...<Widget>[
                _ResultCard(result: result),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => _share(
                  () => widget.share.shareText(
                    report.toText(),
                    subject: l10n.benchmarkTitle,
                  ),
                ),
                icon: const Icon(Icons.share),
                label: Text(l10n.benchmarkShareText),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _share(
                  () => widget.share.shareBytes(
                    Uint8List.fromList(utf8.encode(report.toJsonString())),
                    fileName: 'benchmark_${_fileSafe(model.name)}.json',
                    mimeType: 'application/json',
                    subject: l10n.benchmarkTitle,
                  ),
                ),
                icon: const Icon(Icons.data_object),
                label: Text(l10n.benchmarkShareJson),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fileSafe(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
}

String _acceleratorName(AppLocalizations l10n, AcceleratorPreference p) {
  return switch (p) {
    AcceleratorPreference.cpu => l10n.benchmarkAccelCpu,
    AcceleratorPreference.gpu => l10n.benchmarkAccelGpu,
    AcceleratorPreference.nnapi => l10n.benchmarkAccelNnapi,
    AcceleratorPreference.auto => l10n.benchmarkAccelAuto,
  };
}

String _delegateName(AppLocalizations l10n, DelegateKind k) {
  return switch (k) {
    DelegateKind.cpu => l10n.benchmarkAccelCpu,
    DelegateKind.gpu => l10n.benchmarkAccelGpu,
    DelegateKind.nnapi => l10n.benchmarkAccelNnapi,
  };
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final DelegateBenchmark result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wall = result.wall;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _acceleratorName(l10n, result.requested),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (result.fellBack) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                l10n.benchmarkRanOn(_delegateName(l10n, result.actual!)),
                style: const TextStyle(color: AppColors.warning, fontSize: 13),
              ),
            ],
            const SizedBox(height: 10),
            if (!result.succeeded || wall == null)
              Text(
                l10n.benchmarkFailed(result.error ?? '—'),
                style: const TextStyle(color: Colors.redAccent),
              )
            else ...<Widget>[
              _StatRow(
                l10n.benchmarkMedian,
                '${wall.medianMs.toStringAsFixed(1)} ms',
              ),
              _StatRow(
                l10n.benchmarkMean,
                '${wall.meanMs.toStringAsFixed(1)} ms',
              ),
              _StatRow(
                l10n.benchmarkP90,
                '${wall.p90Ms.toStringAsFixed(1)} ms',
              ),
              _StatRow(
                l10n.benchmarkMin,
                '${wall.minMs.toStringAsFixed(1)} ms',
              ),
              if (result.native != null)
                _StatRow(
                  l10n.benchmarkNative,
                  '${result.native!.medianMs.toStringAsFixed(1)} ms',
                ),
              _StatRow(
                l10n.benchmarkLoad,
                '${result.loadMs.toStringAsFixed(0)} ms',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
