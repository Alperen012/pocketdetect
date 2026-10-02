import 'package:flutter/material.dart';

import '../../core/config/app_flags.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../capture/capture_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../models/models_screen.dart';
import '../preferences/preferences_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'home_dashboard_screen.dart';

/// Tab indices, kept in one place so callbacks cannot drift from the layout.
class _Tab {
  static const int home = 0;
  static const int capture = 1;
}

/// The main navigation: Home, Detect, Models, Settings. The marketplace and
/// profile tabs are added only when [showMarketplace] is on.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.showMarketplace = AppFlags.marketplace});

  final bool showMarketplace;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = _Tab.home;

  void _openPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => PreferencesScreen(
          onGoToCapture: () {
            Navigator.of(routeContext).pop();
            setState(() => _index = _Tab.capture);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          HomeDashboardScreen(
            onOpenCamera: () => setState(() => _index = _Tab.capture),
            onOpenPreferences: _openPreferences,
          ),
          CaptureScreen(isActive: _index == _Tab.capture),
          const ModelsScreen(),
          const SettingsScreen(),
          if (widget.showMarketplace) const MarketplaceScreen(),
          if (widget.showMarketplace) const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.center_focus_strong),
            label: l10n.navCapture,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.memory),
            label: l10n.navModels,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tune),
            label: l10n.navSettings,
          ),
          if (widget.showMarketplace)
            BottomNavigationBarItem(
              icon: const Icon(Icons.store_outlined),
              label: l10n.navMarketplace,
            ),
          if (widget.showMarketplace)
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
        ],
      ),
    );
  }
}
