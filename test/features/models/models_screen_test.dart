import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/models/installed_model.dart';
import 'package:mobile_yolo/core/services/detection_service.dart';
import 'package:mobile_yolo/core/services/download_manager.dart';
import 'package:mobile_yolo/core/services/model_library_service.dart';
import 'package:mobile_yolo/core/services/model_validator.dart';
import 'package:mobile_yolo/features/models/models_screen.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';

class _NoopRecorder implements DownloadRecorder {
  @override
  Future<String?> recordDownload(String modelId, String version) async => null;

  @override
  void markAsDownloaded(String modelId) {}
}

void main() {
  late Directory tmp;
  late ModelLibraryService library;
  late DownloadManager downloads;
  late InstalledModel imported;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    tmp = await Directory.systemTemp.createTemp('models_screen_test');
    library = await ModelLibraryService.create(
      prefs,
      modelsDir: () async => Directory(p.join(tmp.path, 'library')),
    );
    final source = File(p.join(tmp.path, 'helmets.tflite'))
      ..writeAsBytesSync(<int>[1, 2, 3]);
    imported = await library.installFile(
      sourcePath: source.path,
      name: 'helmets',
      validation: const ModelValidationResult.success(
        inputWidth: 320,
        inputHeight: 320,
        inputType: 'INT8',
        outputShape: <int>[1, 7, 2100],
        classCount: 3,
      ),
    );
    downloads = DownloadManager(
      marketplaceService: _NoopRecorder(),
      library: library,
    );
  });

  tearDown(() async {
    downloads.dispose();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Widget app() {
    return MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ModelLibraryService>.value(value: library),
        ChangeNotifierProvider<DetectionService>(
          create: (_) => DetectionService(),
        ),
        ChangeNotifierProvider<DownloadManager>.value(value: downloads),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: const ModelsScreen(),
      ),
    );
  }

  testWidgets('lists the built-in and imported models, built-in active', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text('YOLO26 Nano (INT8)'), findsOneWidget);
    expect(find.text('helmets'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.textContaining('320×320'), findsOneWidget);
  });

  testWidgets('tapping a model activates it', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('helmets'));
    await tester.pumpAndSettle();

    expect(library.activeModel.id, imported.id);
  });

  testWidgets('deleting asks for confirmation, then removes the model', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete "helmets" from this device?'), findsOneWidget);
    // Cancelling keeps the model.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(library.byId(imported.id), isNotNull);

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(library.byId(imported.id), isNull);
    expect(find.text('helmets'), findsNothing);
  });

  testWidgets('the built-in model has no delete action', (tester) async {
    await library.activate(imported.id);
    await tester.pumpWidget(app());

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    expect(find.text('Use this model'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('the menu offers a benchmark that opens its screen', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Benchmark'));
    await tester.pumpAndSettle();

    expect(find.text('Run benchmark'), findsOneWidget);
    expect(find.text('YOLO26 Nano (INT8)'), findsOneWidget);
  });

  testWidgets('the app bar opens the comparison screen', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byTooltip('Compare models'));
    await tester.pumpAndSettle();

    expect(find.text('Model A'), findsOneWidget);
    expect(find.text('Model B'), findsOneWidget);
  });

  testWidgets('rejects a non-http URL without starting a download', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.scrollUntilVisible(find.text('Import from URL'), 100);
    await tester.tap(find.text('Import from URL'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'ftp://example.com/m.tflite',
    );
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid http(s) link.'), findsOneWidget);
    expect(downloads.downloads, isEmpty);
  });
}
