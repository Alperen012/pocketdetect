import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/resolution_profile.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/model_library_service.dart';
import '../models/models_screen.dart';
import '../preferences/preferences_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;
    final l10n = context.l10n;
    // The class filter is built from COCO names, so it only applies to models
    // that use them.
    final supportsLabelFilter = context
        .watch<ModelLibraryService>()
        .activeModel
        .supportsLabelFilter;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.advancedSettings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              l10n.sectionModelArchitecture,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            const _ActiveModelCard(),
            if (supportsLabelFilter) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.checklist, color: AppColors.accent),
                  title: Text(l10n.detectionPreferences),
                  subtitle: Text(
                    l10n.selectedClassCount(controller.selectedLabels.length),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PreferencesScreen(),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.sectionDetectionThresholds,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
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
                        Text(l10n.confidenceThreshold),
                        Text(
                          settings.confidenceThreshold.toStringAsFixed(2),
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.confidenceThreshold,
                      min: 0.1,
                      max: 0.9,
                      onChanged: controller.updateConfidence,
                    ),
                    Text(
                      l10n.confidenceThresholdDesc,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
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
                        Text(
                          settings.iouThreshold.toStringAsFixed(2),
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.iouThreshold,
                      min: 0.1,
                      max: 0.9,
                      onChanged: controller.updateIou,
                    ),
                    Text(
                      l10n.iouThresholdDesc,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.sectionPostProcessing,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
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
            Text(
              l10n.sectionProcessingResolution,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
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
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutLicenses),
                subtitle: Text(l10n.aboutLicensesDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationLegalese: l10n.aboutLegalese,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the active model and opens the model library.
class _ActiveModelCard extends StatelessWidget {
  const _ActiveModelCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final model = context.watch<ModelLibraryService>().activeModel;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.memory, color: AppColors.accent),
        title: Text(model.name),
        subtitle: Text(
          '${model.inputWidth}×${model.inputHeight} · '
          '${l10n.customModelClassCount(model.classCount)} · ${model.quantType}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ModelsScreen())),
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
    if (oldWidget.value != widget.value &&
        _ctrl.text != widget.value.toString()) {
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
