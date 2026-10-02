import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/resolution_profile.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/model_import_wizard.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.advancedSettings),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(l10n.sectionModelArchitecture,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l10n.activeModel, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: settings.modelId,
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'yolo26_nano',
                          child: Text(l10n.yoloNanoInt8),
                        ),
                      ],
                      onChanged: settings.useCustomModel
                          ? null
                          : (value) {
                              if (value != null) {
                                controller.updateModelId(value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.nanoModelDescription,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (settings.useCustomModel)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.customModelActiveWarning,
                          style: const TextStyle(color: AppColors.warning),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.sectionCustomModel,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            if (settings.useCustomModel && settings.customModelPath != null)
              _ActiveCustomModelCard(controller: controller)
            else
              _ImportModelCard(controller: controller),
            const SizedBox(height: 24),
            Text(l10n.sectionDetectionThresholds,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(l10n.confidenceThreshold),
                        Text(settings.confidenceThreshold.toStringAsFixed(2),
                            style: const TextStyle(color: AppColors.accent)),
                      ],
                    ),
                    Slider(
                      value: settings.confidenceThreshold,
                      min: 0.1,
                      max: 0.9,
                      onChanged: controller.updateConfidence,
                    ),
                    Text(l10n.confidenceThresholdDesc,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(l10n.iouThreshold),
                        Text(settings.iouThreshold.toStringAsFixed(2),
                            style: const TextStyle(color: AppColors.accent)),
                      ],
                    ),
                    Slider(
                      value: settings.iouThreshold,
                      min: 0.1,
                      max: 0.9,
                      onChanged: controller.updateIou,
                    ),
                    Text(l10n.iouThresholdDesc,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.sectionPostProcessing,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                value: settings.useNms,
                onChanged: controller.updateUseNms,
                title: Text(l10n.nonMaxSuppression),
                subtitle: Text(l10n.suppressDuplicateBoxes),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(l10n.maxDetections),
                subtitle: Text(l10n.perFrame),
                trailing: _MaxDetectionsField(
                  value: settings.maxDetections,
                  onChanged: controller.updateMaxDetections,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.sectionProcessingResolution,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<ResolutionProfile>(
                  initialValue: settings.resolutionProfile,
                  items: ResolutionProfile.values
                      .map(
                        (profile) => DropdownMenuItem<ResolutionProfile>(
                          value: profile,
                          child: Text(profile.localizedDisplayLabel(l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateResolution(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: controller.resetToDefaults,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.resetToDefaults),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCustomModelCard extends StatelessWidget {
  const _ActiveCustomModelCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = controller.settings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.wizardActiveModelInfo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (settings.customModelName != null)
              _ModelInfoRow(
                icon: Icons.file_present_outlined,
                label: l10n.wizardSummaryModel,
                value: settings.customModelName!,
              ),
            if (settings.customModelInputWidth != null &&
                settings.customModelInputHeight != null)
              _ModelInfoRow(
                icon: Icons.aspect_ratio,
                label: l10n.wizardSummaryInputSize,
                value: l10n.customModelInputSize(
                  settings.customModelInputWidth!,
                  settings.customModelInputHeight!,
                ),
              ),
            if (settings.customModelClassCount != null)
              _ModelInfoRow(
                icon: Icons.category_outlined,
                label: l10n.wizardSummaryClassCount,
                value: l10n.customModelClassCount(
                  settings.customModelClassCount!,
                ),
              ),
            if (settings.customModelQuantType != null)
              _ModelInfoRow(
                icon: Icons.memory,
                label: l10n.wizardSummaryQuantization,
                value: settings.customModelQuantType!,
              ),
            _ModelInfoRow(
              icon: Icons.label_outline,
              label: l10n.wizardSummaryLabelSource,
              value: settings.customLabelsPath != null
                  ? l10n.wizardLabelSourceCustom
                  : l10n.wizardLabelSourceCoco,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ModelImportWizard.show(context, controller);
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: Text(l10n.wizardChangeModel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRemove(context),
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.red.shade400),
                    label: Text(
                      l10n.wizardRemoveModel,
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final l10n = context.l10n;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.wizardRemoveModel),
        content: Text(l10n.wizardRemoveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.wizardRemove,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        controller.updateCustomModelPath(null);
        controller.updateCustomLabelsPath(null);
        controller.updateUseCustomModel(false);
        controller.clearCustomModelMetadata();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.customModelCleared)),
        );
      }
    });
  }
}

class _ImportModelCard extends StatelessWidget {
  const _ImportModelCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_circle_outline,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.wizardImportNewModel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.wizardImportNewModelDesc,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.wizardNoCustomModel,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ModelImportWizard.show(context, controller);
                },
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.wizardImportNewModel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelInfoRow extends StatelessWidget {
  const _ModelInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaxDetectionsField extends StatefulWidget {
  const _MaxDetectionsField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_MaxDetectionsField> createState() => _MaxDetectionsFieldState();
}

class _MaxDetectionsFieldState extends State<_MaxDetectionsField> {
  late TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_MaxDetectionsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.text != widget.value.toString()) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null || raw.isEmpty) {
      setState(() => _error = context.l10n.enterNumber);
      return;
    }
    if (parsed < 1 || parsed > 500) {
      setState(() => _error = context.l10n.rangeOneToFiveHundred);
      return;
    }
    setState(() => _error = null);
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          isDense: true,
          errorText: _error,
          errorStyle: const TextStyle(fontSize: 10),
          border: const OutlineInputBorder(),
        ),
        onChanged: _onChanged,
      ),
    );
  }
}
