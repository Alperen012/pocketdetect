import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/services/model_library_service.dart';
import '../../../core/services/model_validator.dart';
import '../../../core/theme/app_colors.dart';

/// A 4-step wizard (bottom sheet) that guides the user through importing a
/// custom YOLO TFLite model:
///   0 — Format requirements info
///   1 — Pick & validate model file
///   2 — Pick or skip label file
///   3 — Summary + activate
class ModelImportWizard extends StatefulWidget {
  const ModelImportWizard({super.key, required this.library});

  final ModelLibraryService library;

  /// Show the wizard as a modal bottom sheet and return `true` if a model was
  /// successfully imported.
  static Future<bool?> show(BuildContext context, ModelLibraryService library) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ModelImportWizard(library: library),
    );
  }

  @override
  State<ModelImportWizard> createState() => _ModelImportWizardState();
}

class _ModelImportWizardState extends State<ModelImportWizard> {
  int _step = 0;

  // Step 1 — model validation results
  bool _isValidating = false;
  String? _pickedModelPath;
  ModelValidationResult? _modelResult;
  String? _modelError;

  // Step 2 — labels
  String? _pickedLabelsPath;
  LabelValidationResult? _labelsResult;
  String? _labelsError;
  bool _useCocoLabels = false;

  static const _totalSteps = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.modelImportWizardTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StepIndicator(
                currentStep: _step,
                labels: [
                  l10n.wizardStepFormat,
                  l10n.wizardStepModel,
                  l10n.wizardStepLabels,
                  l10n.wizardStepSummary,
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  _buildStepContent(context),
                ],
              ),
            ),
            _buildBottomBar(context),
          ],
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildFormatInfoStep(context);
      case 1:
        return _buildModelStep(context);
      case 2:
        return _buildLabelsStep(context);
      case 3:
        return _buildSummaryStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ──────── STEP 0: Format Requirements ────────

  Widget _buildFormatInfoStep(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.formatRequirementsTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.formatRequirementsBody,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 20),
        _RequirementTile(
          icon: Icons.file_present_outlined,
          text: l10n.formatReqTflite,
        ),
        _RequirementTile(
          icon: Icons.input,
          text: l10n.formatReqInput,
        ),
        _RequirementTile(
          icon: Icons.output,
          text: l10n.formatReqOutput,
        ),
        _RequirementTile(
          icon: Icons.label_outline,
          text: l10n.formatReqLabels,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.formatReqLabelsNote,
                  style: const TextStyle(
                      color: AppColors.warning, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────── STEP 1: Model File ────────

  Widget _buildModelStep(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.wizardSelectModelFile,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.wizardSelectModelDesc,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isValidating ? null : _pickAndValidateModel,
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.wizardSelectModelFile),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (_isValidating) ...[
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  l10n.wizardValidating,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
        if (_modelError != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _modelError!),
        ],
        if (_modelResult != null && _modelResult!.isValid) ...[
          const SizedBox(height: 16),
          _SuccessBanner(
            title: l10n.wizardModelValid,
            details: [
              l10n.wizardModelInputSize(
                _modelResult!.inputWidth!,
                _modelResult!.inputHeight!,
              ),
              l10n.wizardModelClasses(_modelResult!.classCount!),
              l10n.wizardModelQuantType(_modelResult!.inputType!),
            ],
          ),
          if (_pickedModelPath != null) ...[
            const SizedBox(height: 8),
            Text(
              p.basename(_pickedModelPath!),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _pickAndValidateModel() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;

    if (!path.toLowerCase().endsWith('.tflite')) {
      if (!mounted) return;
      setState(() {
        _modelError = context.l10n.wizardErrorNotValidTflite;
        _modelResult = null;
        _pickedModelPath = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _modelError = null;
      _modelResult = null;
      _pickedModelPath = path;
    });

    final validation = await ModelValidator.validate(path);

    if (!mounted) return;
    setState(() {
      _isValidating = false;
      _modelResult = validation;
      if (!validation.isValid) {
        _pickedModelPath = null;
        _modelError = _localizeError(validation.errorCode!);
      }
    });
  }

  String _localizeError(ModelValidationError code) {
    final l10n = context.l10n;
    switch (code) {
      case ModelValidationError.fileNotFound:
        return l10n.wizardErrorFileNotFound;
      case ModelValidationError.notValidTflite:
        return l10n.wizardErrorNotValidTflite;
      case ModelValidationError.unsupportedInputShape:
        return l10n.wizardErrorInputShape;
      case ModelValidationError.unsupportedInputType:
        return l10n.wizardErrorInputType;
      case ModelValidationError.unsupportedOutputShape:
        return l10n.wizardErrorOutputShape;
      case ModelValidationError.unsupportedOutputType:
        return l10n.wizardErrorOutputType;
    }
  }

  // ──────── STEP 2: Labels ────────

  Widget _buildLabelsStep(BuildContext context) {
    final l10n = context.l10n;
    final classCount = _modelResult?.classCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.wizardLabelStepTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.wizardLabelStepDesc(classCount),
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickAndValidateLabels,
            icon: const Icon(Icons.file_open_outlined),
            label: Text(l10n.wizardSelectLabelFile),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _useCocoLabels = true;
                _pickedLabelsPath = null;
                _labelsResult = null;
                _labelsError = null;
              });
            },
            icon: Icon(
              _useCocoLabels
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _useCocoLabels ? AppColors.accent : AppColors.textSecondary,
            ),
            label: Text(l10n.wizardUseCocoLabels),
          ),
        ),
        if (_useCocoLabels && classCount != 80) ...[
          const SizedBox(height: 12),
          _WarningBanner(message: l10n.wizardCocoWarning(classCount)),
        ],
        if (_labelsError != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _labelsError!),
        ],
        if (_labelsResult != null && _labelsResult!.isValid) ...[
          const SizedBox(height: 12),
          _SuccessBanner(
            title: l10n.wizardLabelFileValid(_labelsResult!.labelCount),
            details: [],
          ),
          if (_pickedLabelsPath != null) ...[
            const SizedBox(height: 8),
            Text(
              p.basename(_pickedLabelsPath!),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _pickAndValidateLabels() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.firstOrNull?.path;
    if (path == null || path.isEmpty) return;

    if (!path.toLowerCase().endsWith('.txt')) {
      if (!mounted) return;
      setState(() {
        _labelsError = context.l10n.pleaseSelectTxtFile;
        _labelsResult = null;
        _pickedLabelsPath = null;
        _useCocoLabels = false;
      });
      return;
    }

    final classCount = _modelResult?.classCount ?? 0;
    final validation =
        await ModelValidator.validateLabels(path, expectedCount: classCount);

    if (!mounted) return;
    setState(() {
      _labelsResult = validation;
      _useCocoLabels = false;
      if (validation.isValid) {
        _pickedLabelsPath = path;
        _labelsError = null;
      } else {
        _pickedLabelsPath = null;
        switch (validation.errorCode) {
          case LabelValidationError.fileNotFound:
            _labelsError = context.l10n.wizardLabelFileNotFound;
          case LabelValidationError.countMismatch:
            _labelsError = context.l10n.wizardLabelCountMismatch(
              validation.labelCount,
              classCount,
            );
          case LabelValidationError.readError:
            _labelsError = context.l10n.wizardLabelReadError;
          case null:
            break;
        }
      }
    });
  }

  // ──────── STEP 3: Summary ────────

  Widget _buildSummaryStep(BuildContext context) {
    final l10n = context.l10n;
    final result = _modelResult!;
    final fileName = p.basename(_pickedModelPath!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.wizardSummaryTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SummaryRow(label: l10n.wizardSummaryModel, value: fileName),
        _SummaryRow(
          label: l10n.wizardSummaryInputSize,
          value: '${result.inputWidth}×${result.inputHeight}',
        ),
        _SummaryRow(
          label: l10n.wizardSummaryClassCount,
          value: '${result.classCount}',
        ),
        _SummaryRow(
          label: l10n.wizardSummaryQuantization,
          value: result.inputType ?? '—',
        ),
        _SummaryRow(
          label: l10n.wizardSummaryLabelSource,
          value: _useCocoLabels
              ? l10n.wizardLabelSourceCoco
              : l10n.wizardLabelSourceCustom,
        ),
      ],
    );
  }

  // ──────── Bottom navigation bar ────────

  Widget _buildBottomBar(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                child: Text(l10n.wizardBack),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: _step == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceed ? _onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor:
                    _step == _totalSteps - 1 ? Colors.green : AppColors.primary,
              ),
              child: Text(
                _step == _totalSteps - 1
                    ? l10n.wizardActivateModel
                    : l10n.wizardContinue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _modelResult != null && _modelResult!.isValid;
      case 2:
        return _useCocoLabels ||
            (_labelsResult != null && _labelsResult!.isValid);
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _onNext() async {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }

    // Final step — copy files to app directory and activate.
    await _activateModel();
  }

  Future<void> _activateModel() async {
    final library = widget.library;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final successText = context.l10n.wizardImportSuccess;

    List<String>? labels;
    if (_pickedLabelsPath != null && !_useCocoLabels) {
      labels = (await File(_pickedLabelsPath!).readAsString())
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }

    try {
      final model = await library.installFile(
        sourcePath: _pickedModelPath!,
        name: p.basenameWithoutExtension(_pickedModelPath!),
        validation: _modelResult!,
        labels: labels,
        usesCocoLabels: _useCocoLabels,
      );
      await library.activate(model.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(successText)));
    navigator.pop(true);
  }
}

// ─────────────────── Shared sub-widgets ───────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.labels});

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone || isActive
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.accent
                          : isActive
                              ? AppColors.primary
                              : AppColors.surface,
                      border: Border.all(
                        color: isDone || isActive
                            ? AppColors.accent
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  if (i < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? AppColors.accent : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  color: isActive || isDone
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.warning, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.title, required this.details});

  final String title;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final detail in details)
              Padding(
                padding: const EdgeInsets.only(left: 26, bottom: 2),
                child: Text(
                  detail,
                  style: const TextStyle(
                      color: Colors.green, fontSize: 13, height: 1.3),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
