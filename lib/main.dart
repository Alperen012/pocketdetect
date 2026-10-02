import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/detection_history_service.dart';
import 'core/services/detection_service.dart';
import 'core/services/download_manager.dart';
import 'core/services/marketplace_service.dart';
import 'core/services/model_library_service.dart';
import 'core/services/settings_controller.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global framework error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError caught: ${details.exception}');
    };

    // Custom ErrorWidget for a user-friendly crash screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops! Something went wrong.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode
                        ? details.exception.toString()
                        : 'Please restart the app.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final settingsController = SettingsController(prefs);
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

  // Marketplace services
  final authService = AuthService();
  final marketplaceService = MarketplaceService(prefs);
  final downloadManager = DownloadManager(
    marketplaceService: marketplaceService,
    library: modelLibrary,
  );

  // History
  final historyService = DetectionHistoryService(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>(
          create: (_) => settingsController,
        ),
        ChangeNotifierProvider<ModelLibraryService>(
          create: (_) => modelLibrary,
        ),
        ChangeNotifierProvider<DetectionService>(
          create: (_) => detectionService,
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => authService,
        ),
        ChangeNotifierProvider<MarketplaceService>(
          create: (_) => marketplaceService,
        ),
        ChangeNotifierProvider<DownloadManager>(
          create: (_) => downloadManager,
        ),
        ChangeNotifierProvider<DetectionHistoryService>(
          create: (_) => historyService,
        ),
      ],
      child: const YoloApp(),
    ),
  );
  }, (error, stack) {
    debugPrint('runZonedGuarded caught an error: $error\n$stack');
  });
}
