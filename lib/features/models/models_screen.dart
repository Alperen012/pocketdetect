import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/download_state.dart';
import '../../core/models/installed_model.dart';
import '../../core/services/detection_service.dart';
import '../../core/services/download_manager.dart';
import '../../core/services/model_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../settings/widgets/model_import_wizard.dart';
import 'benchmark_screen.dart';
import 'compare_screen.dart';

/// The model library: pick the active model, import new ones, delete old ones.
class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library = context.watch<ModelLibraryService>();
    final detectionError = context.watch<DetectionService>().error;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.modelsTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.compareTitle,
            icon: const Icon(Icons.compare),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CompareScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            if (detectionError != null) ...<Widget>[
              _ErrorCard(message: '${l10n.modelLoadFailed}\n$detectionError'),
              const SizedBox(height: 12),
            ],
            for (final model in library.models) ...<Widget>[
              _ModelTile(
                model: model,
                isActive: model.id == library.activeModel.id,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ModelImportWizard.show(context, library),
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.modelImportFromFile),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _UrlImportDialog(),
              ),
              icon: const Icon(Icons.link),
              label: Text(l10n.modelImportFromUrl),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({required this.model, required this.isActive});

  final InstalledModel model;
  final bool isActive;

  String _sourceLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (model.origin) {
      InstalledModelOrigin.builtIn => l10n.modelBuiltIn,
      InstalledModelOrigin.file => l10n.modelSourceFile,
      InstalledModelOrigin.url => l10n.modelSourceUrl,
      InstalledModelOrigin.marketplace => l10n.modelSourceMarketplace,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library = context.read<ModelLibraryService>();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? AppColors.accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle : Icons.memory,
          color: isActive ? AppColors.accent : AppColors.textSecondary,
        ),
        title: Text(model.name),
        subtitle: Text(
          '${model.inputWidth}×${model.inputHeight} · '
          '${l10n.customModelClassCount(model.classCount)} · '
          '${model.quantType}\n${_sourceLabel(context)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isActive)
              Text(
                l10n.modelActive,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'use':
                    library.activate(model.id);
                  case 'benchmark':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BenchmarkScreen(model: model),
                      ),
                    );
                  case 'delete':
                    _confirmDelete(context, library);
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                if (!isActive)
                  PopupMenuItem<String>(
                    value: 'use',
                    child: Text(l10n.modelUse),
                  ),
                PopupMenuItem<String>(
                  value: 'benchmark',
                  child: Text(l10n.benchmarkTitle),
                ),
                if (!model.isBuiltIn)
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      l10n.modelDelete,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: isActive ? null : () => library.activate(model.id),
        onLongPress:
            model.isBuiltIn ? null : () => _confirmDelete(context, library),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ModelLibraryService library,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.modelDelete),
        content: Text(l10n.modelDeleteConfirm(model.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.modelDelete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await library.remove(model.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.modelDeleted)));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }
}

/// Asks for a link to a `.tflite` file, downloads it and activates it.
class _UrlImportDialog extends StatefulWidget {
  const _UrlImportDialog();

  @override
  State<_UrlImportDialog> createState() => _UrlImportDialogState();
}

class _UrlImportDialogState extends State<_UrlImportDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _url;
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = context.l10n;
    final text = _controller.text.trim();
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      setState(() => _validationError = l10n.modelUrlInvalid);
      return;
    }

    final dm = context.read<DownloadManager>();
    final library = context.read<ModelLibraryService>();
    final navigator = Navigator.of(context);
    setState(() {
      _url = text;
      _validationError = null;
    });

    final model = await dm.importFromUrl(text);
    if (model != null) {
      await library.activate(model.id);
      if (navigator.mounted) navigator.pop();
    }
    // On failure the dialog stays open and shows the error from the manager.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = _url == null
        ? null
        : context.watch<DownloadManager>().getDownloadState(_url!);
    final busy = state != null &&
        (state.isDownloading || state.status == DownloadStatus.validating);
    final failure = state != null && state.isFailed;

    return AlertDialog(
      title: Text(l10n.modelUrlDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            enabled: !busy,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.modelUrlHint,
              errorText: _validationError,
            ),
            onSubmitted: (_) => busy ? null : _start(),
          ),
          if (busy) ...<Widget>[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: state.status == DownloadStatus.validating
                  ? null
                  : state.progress,
            ),
            const SizedBox(height: 8),
            Text(
              state.status == DownloadStatus.validating
                  ? l10n.modelValidating
                  : l10n.modelDownloading,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (failure) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              l10n.modelDownloadFailed(state.error ?? ''),
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            final url = _url;
            if (busy && url != null) {
              context.read<DownloadManager>().cancelDownload(url);
            }
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: busy ? null : _start,
          child: Text(l10n.modelDownload),
        ),
      ],
    );
  }
}
