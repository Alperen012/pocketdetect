import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/services/detection_history_service.dart';
import 'package:mobile_yolo/core/services/settings_controller.dart';
import 'package:mobile_yolo/features/home/home_dashboard_screen.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';

/// Helper that wraps a widget with the minimum required providers and
/// localization delegates for testing.
Widget buildTestApp(
  Widget child,
  SettingsController settingsController,
  DetectionHistoryService historyService,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(
        value: settingsController,
      ),
      ChangeNotifierProvider<DetectionHistoryService>.value(
        value: historyService,
      ),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('HomeDashboardScreen', () {
    late SettingsController settingsController;
    late DetectionHistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settingsController = SettingsController(prefs);
      historyService = DetectionHistoryService(prefs);
    });

    testWidgets('renders app title and quick action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          HomeDashboardScreen(onOpenCamera: () {}, onOpenPreferences: () {}),
          settingsController,
          historyService,
        ),
      );
      await tester.pumpAndSettle();

      // The app title should be rendered
      expect(find.text('YOLO Mobile'), findsOneWidget);

      // Should show the start camera button
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);

      // Should show the edit preferences button
      expect(find.byIcon(Icons.settings_suggest_outlined), findsOneWidget);
    });

    testWidgets('tapping camera button triggers callback', (
      WidgetTester tester,
    ) async {
      var cameraOpened = false;

      await tester.pumpWidget(
        buildTestApp(
          HomeDashboardScreen(
            onOpenCamera: () => cameraOpened = true,
            onOpenPreferences: () {},
          ),
          settingsController,
          historyService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      expect(cameraOpened, isTrue);
    });

    testWidgets('tapping preferences button triggers callback', (
      WidgetTester tester,
    ) async {
      var prefsOpened = false;

      await tester.pumpWidget(
        buildTestApp(
          HomeDashboardScreen(
            onOpenCamera: () {},
            onOpenPreferences: () => prefsOpened = true,
          ),
          settingsController,
          historyService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_suggest_outlined));
      expect(prefsOpened, isTrue);
    });

    testWidgets('displays current settings summary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          HomeDashboardScreen(onOpenCamera: () {}, onOpenPreferences: () {}),
          settingsController,
          historyService,
        ),
      );
      await tester.pumpAndSettle();

      // Should display confidence threshold (default: 0.50)
      expect(find.textContaining('0.50'), findsOneWidget);
    });
  });
}
