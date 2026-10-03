import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/generated/app_localizations.dart';

class YoloApp extends StatelessWidget {
  const YoloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketDetect',
      theme: AppTheme.dark(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      home: const AppHome(),
    );
  }
}

/// First launch shows the introduction; afterwards the main navigation.
class AppHome extends StatelessWidget {
  const AppHome({super.key, this.shell = const HomeShell()});

  /// The main navigation; replaceable so the gate can be tested in isolation.
  final Widget shell;

  @override
  Widget build(BuildContext context) {
    final seen = context.select<SettingsController, bool>(
      (settings) => settings.settings.onboardingSeen,
    );
    return seen ? shell : const OnboardingScreen();
  }
}
