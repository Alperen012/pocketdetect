import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/app.dart';
import 'package:mobile_yolo/core/services/detection_history_service.dart';
import 'package:mobile_yolo/core/services/detection_service.dart';
import 'package:mobile_yolo/core/services/download_manager.dart';
import 'package:mobile_yolo/core/services/model_library_service.dart';
import 'package:mobile_yolo/core/services/settings_controller.dart';
import 'package:mobile_yolo/features/home/home_shell.dart';
import 'package:mobile_yolo/features/onboarding/onboarding_screen.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations_en.dart';

void main() {
  late Directory tmp;
  late SettingsController settings;
  late ModelLibraryService library;
  late DetectionHistoryService history;
  late DownloadManager downloads;
  final en = AppLocalizationsEn();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    tmp = await Directory.systemTemp.createTemp('home_shell_test');
    settings = SettingsController(prefs);
    library = await ModelLibraryService.create(
      prefs,
      modelsDir: () async => Directory(p.join(tmp.path, 'library')),
    );
    history = DetectionHistoryService(prefs);
    downloads = DownloadManager(
      marketplaceService: const NoopDownloadRecorder(),
      library: library,
    );
  });

  tearDown(() async {
    downloads.dispose();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<ModelLibraryService>.value(value: library),
        ChangeNotifierProvider<DetectionHistoryService>.value(value: history),
        ChangeNotifierProvider<DownloadManager>.value(value: downloads),
        ChangeNotifierProvider<DetectionService>(
          create: (_) => DetectionService(),
        ),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: home,
      ),
    );
  }

  group('HomeShell', () {
    testWidgets('has four tabs and no marketplace or profile by default',
        (tester) async {
      await tester.pumpWidget(wrap(const HomeShell(showMarketplace: false)));

      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(
        bar.items.map((i) => i.label),
        <String?>[en.navHome, en.navCapture, en.navModels, en.navSettings],
      );
      expect(find.text(en.navMarketplace), findsNothing);
      expect(find.text(en.navProfile), findsNothing);
    });

    testWidgets('the Models tab shows the model library', (tester) async {
      await tester.pumpWidget(wrap(const HomeShell(showMarketplace: false)));

      await tester.tap(find.text(en.navModels));
      await tester.pump();

      expect(find.text('YOLO26 Nano (INT8)'), findsWidgets);
      expect(find.text(en.modelImportFromFile), findsOneWidget);
    });

    testWidgets('the Settings tab links to detection classes for COCO models',
        (tester) async {
      await tester.pumpWidget(wrap(const HomeShell(showMarketplace: false)));

      await tester.tap(find.text(en.navSettings));
      await tester.pump();

      expect(find.text(en.detectionPreferences), findsOneWidget);
    });

    testWidgets('the dashboard opens class preferences, which return to Detect',
        (tester) async {
      await tester.pumpWidget(wrap(const HomeShell(showMarketplace: false)));

      await tester.tap(find.byIcon(Icons.settings_suggest_outlined));
      await tester.pumpAndSettle();
      expect(find.text(en.whatToDetect), findsOneWidget);

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pumpAndSettle();

      // Back on the shell, with the Detect tab selected.
      expect(find.text(en.whatToDetect), findsNothing);
      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, 1);
    });
  });

  group('AppHome', () {
    testWidgets('shows the introduction until it is dismissed', (tester) async {
      await tester.pumpWidget(wrap(const AppHome(shell: Text('SHELL'))));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('SHELL'), findsNothing);
      expect(find.text(en.onboardingTitle), findsOneWidget);
      expect(find.text(en.onboardingCameraBody), findsOneWidget);

      await tester.tap(find.text(en.onboardingStart));
      await tester.pump();

      expect(find.text('SHELL'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(settings.settings.onboardingSeen, isTrue);
    });

    testWidgets('goes straight to the app once seen', (tester) async {
      settings.markOnboardingSeen();

      await tester.pumpWidget(wrap(const AppHome(shell: Text('SHELL'))));

      expect(find.text('SHELL'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });
  });
}
