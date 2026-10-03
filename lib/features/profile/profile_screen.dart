import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extensions.dart';
import '../../core/models/category_group.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/detection_service.dart';
import '../../core/services/download_manager.dart';
import '../../core/services/model_library_service.dart';
import '../../core/services/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../preferences/preferences_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final detectionService = context.watch<DetectionService>();
    final activeModel = context.watch<ModelLibraryService>().activeModel;
    final l10n = context.l10n;

    final selected = settings.selectedLabels;
    final coveredGroups = cocoGroups
        .where((group) => group.items.any(selected.contains))
        .length;
    final totalLabels = cocoGroups
        .expand((group) => group.items)
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF1B63FF), Color(0xFF22D3EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black26,
                    child: Icon(Icons.person_outline, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.defaultUserName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: <Shadow>[
                              Shadow(blurRadius: 4, color: Colors.black38),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.localProfileOnDevice,
                          style: const TextStyle(
                            color: Colors.white70,
                            shadows: <Shadow>[
                              Shadow(blurRadius: 4, color: Colors.black38),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricCard(
                    title: l10n.selectedClasses,
                    value: '${selected.length}/$totalLabels',
                    icon: Icons.category_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: l10n.category,
                    value: '$coveredGroups/${cocoGroups.length}',
                    icon: Icons.grid_view_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.detectionStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(
                    label: l10n.model,
                    value: detectionService.isReady
                        ? l10n.ready
                        : l10n.notReady,
                    isPositive: detectionService.isReady,
                    isDanger: !detectionService.isReady,
                  ),
                  _StatusRow(
                    label: l10n.modelIdLabel,
                    value: activeModel.name,
                    isPositive: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                  _StatusRow(
                    label: l10n.wizardSummaryInputSize,
                    value:
                        '${activeModel.inputWidth}×${activeModel.inputHeight}',
                    isPositive: true,
                  ),
                  _StatusRow(
                    label: l10n.wizardSummaryClassCount,
                    value: '${activeModel.classCount}',
                    isPositive: true,
                  ),
                  _StatusRow(
                    label: l10n.wizardSummaryQuantization,
                    value: activeModel.quantType,
                    isPositive: true,
                  ),
                  _StatusRow(
                    label: l10n.resolution,
                    value: settings.settings.resolutionProfile
                        .localizedDisplayLabel(l10n),
                    isPositive: true,
                  ),
                  _StatusRow(
                    label: l10n.nms,
                    value: settings.settings.useNms
                        ? l10n.statusOn
                        : l10n.statusOff,
                    isPositive: settings.settings.useNms,
                  ),
                  if (detectionService.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade700),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                detectionService.error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.quickActions,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PreferencesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.editDetectionPreferences),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.memory_outlined),
                      label: Text(l10n.modelAndPerformanceSettings),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _confirmReset(context, settings),
                      icon: const Icon(Icons.restore),
                      label: Text(l10n.resetSettingsToDefaults),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ─── Marketplace Account ─────────────────────
            Consumer<AuthService>(
              builder: (context, auth, _) {
                if (!auth.isAuthenticated) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.store_outlined,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.profileMarketplace,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  l10n.profileSignInToPublish,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final profile = auth.profile;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.store_outlined,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profileMarketplaceAccount,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => auth.signOut(),
                            child: Text(
                              l10n.profileSignOut,
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile?.displayName ?? profile?.username ?? 'User',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        auth.currentUser?.email ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // ─── Downloaded Models ────────────────────────
            Consumer<DownloadManager>(
              builder: (context, dm, _) {
                final library = context.read<ModelLibraryService>();
                final downloaded = dm.downloadedModels;
                if (downloaded.isEmpty) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.download_done_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profileDownloadedModels,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${downloaded.length}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...downloaded.map(
                        (meta) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.model_training,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meta.version == null
                                          ? meta.name
                                          : '${meta.name} v${meta.version}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${meta.inputWidth}×${meta.inputHeight} · ${meta.classCount} classes · ${meta.quantType}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => library.activate(meta.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.profileActivate,
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    SettingsController settings,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetSettingsTitle),
        content: Text(l10n.resetSettingsConfirmation),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      settings.resetToDefaults();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsResetSuccess)));
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.isPositive,
    this.isDanger = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isPositive;
  final bool isDanger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color chipColor = isDanger
        ? Colors.red
        : (isPositive ? Colors.green : AppColors.warning);
    final Color textColor = isDanger
        ? Colors.red.shade300
        : (isPositive ? Colors.greenAccent.shade100 : AppColors.warning);

    final badge = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: onTap != null
              ? Border.all(color: chipColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          badge,
        ],
      ),
    );
  }
}
