import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extensions.dart';

import '../../core/theme/app_colors.dart';
import '../capture/capture_screen.dart';
import '../marketplace/marketplace_screen.dart';
import 'home_dashboard_screen.dart';
import '../preferences/preferences_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          HomeDashboardScreen(
            onOpenCamera: () => setState(() => _index = 1),
            onOpenPreferences: () => setState(() => _index = 2),
          ),
          CaptureScreen(isActive: _index == 1),
          PreferencesScreen(onGoToCapture: () => setState(() => _index = 1)),
          const MarketplaceScreen(),
          const ProfileScreen(),
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
            label: context.l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.center_focus_strong),
            label: context.l10n.navCapture,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tune),
            label: context.l10n.navPreferences,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            label: context.l10n.navMarketplace,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
