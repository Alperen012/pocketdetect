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

    final destinations = <_Destination>[
      _Destination(Icons.home_outlined, l10n.navHome),
      _Destination(Icons.center_focus_strong, l10n.navCapture),
      _Destination(Icons.memory, l10n.navModels),
      _Destination(Icons.tune, l10n.navSettings),
      if (widget.showMarketplace)
        _Destination(Icons.store_outlined, l10n.navMarketplace),
      if (widget.showMarketplace) _Destination(Icons.person, l10n.navProfile),
    ];
    final body = IndexedStack(
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
    );

    // Landscape: a side rail keeps the full height for the content.
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            SafeArea(
              child: NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (value) =>
                    setState(() => _index = value),
                backgroundColor: AppColors.background,
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: const IconThemeData(
                  color: AppColors.primary,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.primary,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: AppColors.textSecondary,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),
                destinations: <NavigationRailDestination>[
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: <BottomNavigationBarItem>[
          for (final d in destinations)
            BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.label);

  final IconData icon;
  final String label;
}
