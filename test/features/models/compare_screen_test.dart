import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/models/app_settings.dart';
import 'package:mobile_yolo/core/models/detected_object.dart';
import 'package:mobile_yolo/core/models/installed_model.dart';
import 'package:mobile_yolo/core/services/model_library_service.dart';
import 'package:mobile_yolo/core/services/model_validator.dart';
import 'package:mobile_yolo/core/services/settings_controller.dart';
import 'package:mobile_yolo/features/models/compare_screen.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';

void main() {
  late Directory tmp;
  late ModelLibraryService library;
  late SettingsController settings;
  late File picture;
  late InstalledModel second;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    tmp = await Directory.systemTemp.createTemp('compare_screen_test');
    library = await ModelLibraryService.create(
      prefs,
      modelsDir: () async => Directory(p.join(tmp.path, 'library')),
    );
    settings = SettingsController(prefs);
    picture = File(p.join(tmp.path, 'pic.png'))
      ..writeAsBytesSync(img.encodePng(img.Image(width: 8, height: 4)));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> addSecondModel() async {
    final source = File(p.join(tmp.path, 'second.tflite'))
      ..writeAsBytesSync(<int>[1]);
    second = await library.installFile(
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
  }

  Widget app({required CompareRunner runner, Future<File?> Function()? pick}) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ModelLibraryService>.value(value: library),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: CompareScreen(
          runner: runner,
          pickImage: pick ?? () async => picture,
        ),
      ),
    );
  }

  // ElevatedButton.icon builds a private subclass, so match by subtype.
  Finder compareButton() => find.ancestor(
    of: find.text('Compare'),
    matching: find.bySubtype<ElevatedButton>(),
  );

  testWidgets('with a single model it explains and cannot compare', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        runner:
            ({
              required model,
              required image,
              required settings,
              required selectedLabels,
            }) async => CompareSide(model: model),
      ),
    );

    expect(
      find.text('Import a second model to compare two models side by side.'),
      findsOneWidget,
    );
    expect(tester.widget<ElevatedButton>(compareButton()).onPressed, isNull);
  });

  testWidgets('compare stays disabled until an image is chosen', (
    tester,
  ) async {
    // Real file I/O must run outside the test's fake-async zone.
    await tester.runAsync(addSecondModel);
    await tester.pumpWidget(
      app(
        runner:
            ({
              required model,
              required image,
              required settings,
              required selectedLabels,
            }) async => CompareSide(model: model),
      ),
    );

    expect(tester.widget<ElevatedButton>(compareButton()).onPressed, isNull);

    await tester.tap(find.text('Choose image'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(compareButton()).onPressed, isNotNull);
    expect(find.text('Change image'), findsOneWidget);
  });

  testWidgets(
    'runs the active model then the other one and shows both results',
    (tester) async {
      // Real file I/O must run outside the test's fake-async zone.
      await tester.runAsync(addSecondModel);
      final calls = <String>[];

      await tester.pumpWidget(
        app(
          runner:
              ({
                required model,
                required image,
                required settings,
                required selectedLabels,
              }) async {
                calls.add(model.name);
                expect(image.path, picture.path);
                expect(settings, isA<AppSettings>());
                return model.isBuiltIn
                    ? CompareSide(
                        model: model,
                        inferenceMs: 30,
                        detections: <DetectedObject>[
                          const DetectedObject(
                            label: 'person',
                            confidence: 0.9,
                            boundingBox: Rect.fromLTWH(0.1, 0.1, 0.4, 0.4),
                          ),
                          const DetectedObject(
                            label: 'dog',
                            confidence: 0.8,
                            boundingBox: Rect.fromLTWH(0.5, 0.5, 0.4, 0.4),
                          ),
                        ],
                      )
                    : CompareSide(model: model, inferenceMs: 55);
              },
        ),
      );

      await tester.tap(find.text('Choose image'));
      await tester.pump();
      await tester.tap(compareButton());
      await tester.pump();
      await tester.pump();

      expect(calls, <String>['YOLO26 Nano (INT8)', 'helmets']);
      expect(find.text('2 objects · 30 ms'), findsOneWidget);
      expect(find.text('0 objects · 55 ms'), findsOneWidget);
    },
  );

  testWidgets('a model that fails does not hide the other result', (
    tester,
  ) async {
    // Real file I/O must run outside the test's fake-async zone.
    await tester.runAsync(addSecondModel);

    await tester.pumpWidget(
      app(
        runner:
            ({
              required model,
              required image,
              required settings,
              required selectedLabels,
            }) async => model.isBuiltIn
            ? CompareSide(model: model, inferenceMs: 20)
            : CompareSide(model: model, error: 'bad tensor'),
      ),
    );

    await tester.tap(find.text('Choose image'));
    await tester.pump();
    await tester.tap(compareButton());
    await tester.pump();
    await tester.pump();

    expect(find.text('0 objects · 20 ms'), findsOneWidget);
    expect(find.text('Could not run helmets: bad tensor'), findsOneWidget);
    expect(second.name, 'helmets');
  });
}
