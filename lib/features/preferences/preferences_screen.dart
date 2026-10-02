import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/category_group.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key, this.onGoToCapture});

  final VoidCallback? onGoToCapture;

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final l10n = context.l10n;
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredGroups = normalizedQuery.isEmpty
        ? cocoGroups
        : cocoGroups.where((group) {
            final labelMatch = group.label.toLowerCase().contains(normalizedQuery);
            final itemMatch = group.items.any(
              (item) => item.toLowerCase().contains(normalizedQuery),
            );
            return labelMatch || itemMatch;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detectionPreferences),
        actions: <Widget>[
          TextButton(
            onPressed: settings.resetToDefaults,
            child: Text(l10n.reset),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.whatToDetect,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectCategoriesDesc,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.searchCategories,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredGroups.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noCategoryFound,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];
                        final isSelected = settings.isGroupSelected(group);
                        final isPartial = settings.isGroupPartiallySelected(group);
                        return Card(
                          child: ExpansionTile(
                            title: Text(group.localizedLabel(l10n)),
                            subtitle: isPartial
                                ? Text(l10n.partiallySelected)
                                : Text(l10n.classCount(group.items.length)),
                            trailing: Switch(
                              value: isSelected,
                              onChanged: (value) =>
                                  settings.setGroupSelection(group, value),
                            ),
                            children: group.items
                                .map(
                                  (item) => SwitchListTile(
                                    value: settings.selectedLabels.contains(item),
                                    onChanged: (_) => settings.toggleLabel(item),
                                    title: Text(item),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: filteredGroups.length,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    if (widget.onGoToCapture != null) {
                      widget.onGoToCapture!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.camera_alt_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.goToCamera(settings.selectedLabels.length),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
