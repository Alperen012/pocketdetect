import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_flags.dart';
import 'core/config/supabase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/detection_history_service.dart';
import 'core/services/detection_service.dart';
import 'core/services/device_capabilities.dart';
import 'core/services/download_manager.dart';
import 'core/services/marketplace_service.dart';
import 'core/services/model_library_service.dart';
import 'core/services/settings_controller.dart';
import 'core/ui/crash_screen.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global framework error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError caught: ${details.exception}');
      };

      // Custom ErrorWidget for a user-friendly crash screen
      ErrorWidget.builder = (FlutterErrorDetails details) => buildCrashScreen(
        details,
        language: ui.PlatformDispatcher.instance.locale.languageCode,
      );

      // The marketplace is optional: without the flag the app never touches
      // Supabase and works without an account or a network.
      if (AppFlags.marketplace) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final settingsController = SettingsController(prefs);
      settingsController.applyDeviceDefaults(
        lowRam: await const DeviceCapabilities().isLowRamDevice(),
      );

      final modelLibrary = await ModelLibraryService.create(
        prefs,
        modelsDir: () async {
          final docs = await getApplicationDocumentsDirectory();
          return Directory(p.join(docs.path, 'models'));
        },
      );
      final detectionService = DetectionService();
      await detectionService.initialize(model: modelLibrary.activeModel);

      // Swap the loaded model whenever the active model changes (import, delete,
      // activate), so a bad or removed model never lingers until the next run.
      modelLibrary.addListener(() {
        detectionService.reloadIfNeeded(modelLibrary.activeModel);
      });

      final authService = AppFlags.marketplace ? AuthService() : null;
      final marketplaceService = AppFlags.marketplace
          ? MarketplaceService(prefs)
          : null;
      final downloadManager = DownloadManager(
        marketplaceService: marketplaceService ?? const NoopDownloadRecorder(),
        library: modelLibrary,
      );

      final historyService = DetectionHistoryService(prefs);

      runApp(
        MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<SettingsController>(
              create: (_) => settingsController,
            ),
            ChangeNotifierProvider<ModelLibraryService>(
              create: (_) => modelLibrary,
            ),
            ChangeNotifierProvider<DetectionService>(
              create: (_) => detectionService,
            ),
            ChangeNotifierProvider<DownloadManager>(
              create: (_) => downloadManager,
            ),
            ChangeNotifierProvider<DetectionHistoryService>(
              create: (_) => historyService,
            ),
            if (authService != null)
              ChangeNotifierProvider<AuthService>(create: (_) => authService),
            if (marketplaceService != null)
              ChangeNotifierProvider<MarketplaceService>(
                create: (_) => marketplaceService,
              ),
          ],
          child: const YoloApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('runZonedGuarded caught an error: $error\n$stack');
    },
  );
}
