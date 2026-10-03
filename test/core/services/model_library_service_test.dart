import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/models/installed_model.dart';
import 'package:mobile_yolo/core/services/model_library_service.dart';
import 'package:mobile_yolo/core/services/model_validator.dart';

ModelValidationResult validModel({int classes = 3}) =>
    ModelValidationResult.success(
      inputWidth: 640,
      inputHeight: 640,
      inputType: 'INT8',
      outputShape: <int>[1, 4 + classes, 8400],
      classCount: classes,
    );

void main() {
  late Directory tmp;
  late SharedPreferences prefs;
  late File source;
  var idCounter = 0;

  Future<ModelLibraryService> openLibrary() => ModelLibraryService.create(
    prefs,
    modelsDir: () async => Directory(p.join(tmp.path, 'library')),
    idGenerator: () => 'id${++idCounter}',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    tmp = await Directory.systemTemp.createTemp('model_library_test');
    source = File(p.join(tmp.path, 'picked.tflite'))
      ..writeAsBytesSync(<int>[1, 2, 3, 4, 5]);
    idCounter = 0;
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('ModelLibraryService', () {
    test('starts with only the bundled model, active', () async {
      final lib = await openLibrary();

      expect(lib.models, hasLength(1));
      expect(lib.models.single.isBuiltIn, isTrue);
      expect(lib.activeModel.id, InstalledModel.builtInId);
    });

    test('installFile copies the file and generates class names', () async {
      final lib = await openLibrary();
      var notified = 0;
      lib.addListener(() => notified++);

      final model = await lib.installFile(
        sourcePath: source.path,
        name: 'helmets',
        validation: validModel(),
      );

      expect(model.id, 'id1');
      expect(model.filePath, isNot(source.path));
      expect(File(model.filePath!).readAsBytesSync(), <int>[1, 2, 3, 4, 5]);
      expect(model.fileSizeBytes, 5);
      expect(model.labels, <String>['class_0', 'class_1', 'class_2']);
      expect(model.usesCocoLabels, isFalse);
      expect(model.supportsLabelFilter, isFalse);
      expect(model.quantType, 'INT8');
      expect(lib.models.map((m) => m.id), <String>[
        InstalledModel.builtInId,
        'id1',
      ]);
      expect(notified, 1);
    });

    test('keeps a model usable after the picked file is deleted', () async {
      final lib = await openLibrary();
      final model = await lib.installFile(
        sourcePath: source.path,
        name: 'm',
        validation: validModel(),
      );

      source.deleteSync();

      expect(File(model.filePath!).existsSync(), isTrue);
    });

    test('uses provided labels', () async {
      final lib = await openLibrary();
      final model = await lib.installFile(
        sourcePath: source.path,
        name: 'm',
        validation: validModel(),
        labels: <String>['helmet', 'vest', 'person'],
      );

      expect(model.labels, <String>['helmet', 'vest', 'person']);
      expect(model.usesCocoLabels, isFalse);
    });

    test(
      'COCO labels mean no explicit list and a usable label filter',
      () async {
        final lib = await openLibrary();
        final model = await lib.installFile(
          sourcePath: source.path,
          name: 'coco',
          validation: validModel(classes: 80),
          usesCocoLabels: true,
        );

        expect(model.labels, isEmpty);
        expect(model.usesCocoLabels, isTrue);
        expect(model.supportsLabelFilter, isTrue);
      },
    );

    test(
      'rejects a label list whose length differs from the class count',
      () async {
        final lib = await openLibrary();

        expect(
          () => lib.installFile(
            sourcePath: source.path,
            name: 'm',
            validation: validModel(classes: 3),
            labels: <String>['only', 'two'],
          ),
          throwsArgumentError,
        );
        expect(lib.models, hasLength(1));
      },
    );

    test('rejects a model that failed validation', () async {
      final lib = await openLibrary();

      expect(
        () => lib.installFile(
          sourcePath: source.path,
          name: 'm',
          validation: const ModelValidationResult.failure(
            ModelValidationError.notValidTflite,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('a failed copy leaves no half-installed model', () async {
      final lib = await openLibrary();

      await expectLater(
        lib.installFile(
          sourcePath: p.join(tmp.path, 'missing.tflite'),
          name: 'm',
          validation: validModel(),
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(lib.models, hasLength(1));
      expect(
        Directory(p.join(tmp.path, 'library', 'id1')).existsSync(),
        isFalse,
      );
    });

    test('activate switches the active model and notifies', () async {
      final lib = await openLibrary();
      final model = await lib.installFile(
        sourcePath: source.path,
        name: 'm',
        validation: validModel(),
      );
      var notified = 0;
      lib.addListener(() => notified++);

      await lib.activate(model.id);

      expect(lib.activeModel.id, model.id);
      expect(notified, 1);

      await lib.activate(model.id); // no-op
      expect(notified, 1);

      await lib.activate('does-not-exist'); // ignored
      expect(lib.activeModel.id, model.id);
    });

    test('rename updates the name', () async {
      final lib = await openLibrary();
      final model = await lib.installFile(
        sourcePath: source.path,
        name: 'old',
        validation: validModel(),
      );

      await lib.rename(model.id, 'new');

      expect(lib.byId(model.id)!.name, 'new');
    });

    test(
      'remove deletes the file and falls back to the bundled model',
      () async {
        final lib = await openLibrary();
        final model = await lib.installFile(
          sourcePath: source.path,
          name: 'm',
          validation: validModel(),
        );
        await lib.activate(model.id);

        await lib.remove(model.id);

        expect(lib.activeModel.isBuiltIn, isTrue);
        expect(lib.byId(model.id), isNull);
        expect(File(model.filePath!).existsSync(), isFalse);
        expect(Directory(p.dirname(model.filePath!)).existsSync(), isFalse);
      },
    );

    test('the bundled model cannot be removed', () async {
      final lib = await openLibrary();

      await lib.remove(InstalledModel.builtInId);

      expect(lib.models, hasLength(1));
    });

    test('state survives reopening the library', () async {
      final lib = await openLibrary();
      final model = await lib.installFile(
        sourcePath: source.path,
        name: 'persisted',
        validation: validModel(),
        labels: <String>['a', 'b', 'c'],
      );
      await lib.activate(model.id);

      final reopened = await openLibrary();

      expect(reopened.activeModel.id, model.id);
      expect(reopened.activeModel.name, 'persisted');
      expect(reopened.activeModel.labels, <String>['a', 'b', 'c']);
    });

    test(
      'drops models whose file disappeared and resets the active one',
      () async {
        final lib = await openLibrary();
        final model = await lib.installFile(
          sourcePath: source.path,
          name: 'gone',
          validation: validModel(),
        );
        await lib.activate(model.id);
        File(model.filePath!).deleteSync();

        final reopened = await openLibrary();

        expect(reopened.models, hasLength(1));
        expect(reopened.activeModel.isBuiltIn, isTrue);
      },
    );

    test('survives corrupted stored data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'installed_models_v1': '{not json',
      });
      prefs = await SharedPreferences.getInstance();

      final lib = await openLibrary();

      expect(lib.models, hasLength(1));
    });

    test('finds a model by marketplace id', () async {
      final lib = await openLibrary();
      final model = await lib.installFile(
        sourcePath: source.path,
        name: 'm',
        validation: validModel(),
        origin: InstalledModelOrigin.marketplace,
        marketplaceModelId: 'mp-42',
        version: '1.2.0',
      );

      expect(lib.byMarketplaceId('mp-42')!.id, model.id);
      expect(lib.byMarketplaceId('other'), isNull);
      expect(model.version, '1.2.0');
    });
  });

  group('legacy settings migration', () {
    test('imports the old custom model and activates it', () async {
      final legacyModel = File(p.join(tmp.path, 'custom_models', 'old.tflite'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[9, 9]);
      final legacyLabels = File(p.join(tmp.path, 'custom_models', 'old.txt'))
        ..writeAsStringSync('helmet\nvest\n');
      SharedPreferences.setMockInitialValues(<String, Object>{
        'use_custom_model': true,
        'custom_model_path': legacyModel.path,
        'custom_labels_path': legacyLabels.path,
        'custom_model_name': 'old.tflite',
        'custom_model_input_width': 320,
        'custom_model_input_height': 320,
        'custom_model_class_count': 2,
        'custom_model_quant_type': 'INT8',
        'model_id': 'yolo26_nano',
      });
      prefs = await SharedPreferences.getInstance();

      final lib = await openLibrary();

      expect(lib.models, hasLength(2));
      final migrated = lib.activeModel;
      expect(migrated.isBuiltIn, isFalse);
      expect(migrated.name, 'old.tflite');
      expect(migrated.filePath, legacyModel.path);
      expect(migrated.labels, <String>['helmet', 'vest']);
      expect(migrated.inputWidth, 320);
      expect(migrated.classCount, 2);
      expect(migrated.quantType, 'INT8');
      expect(prefs.containsKey('custom_model_path'), isFalse);
      expect(prefs.containsKey('use_custom_model'), isFalse);
      expect(prefs.containsKey('model_id'), isFalse);
    });

    test(
      'keeps the bundled model active when the old toggle was off',
      () async {
        final legacyModel = File(p.join(tmp.path, 'old.tflite'))
          ..writeAsBytesSync(<int>[1]);
        SharedPreferences.setMockInitialValues(<String, Object>{
          'use_custom_model': false,
          'custom_model_path': legacyModel.path,
        });
        prefs = await SharedPreferences.getInstance();

        final lib = await openLibrary();

        expect(lib.models, hasLength(2));
        expect(lib.activeModel.isBuiltIn, isTrue);
        expect(lib.models.last.usesCocoLabels, isTrue);
      },
    );

    test('ignores an old path whose file no longer exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'use_custom_model': true,
        'custom_model_path': p.join(tmp.path, 'nope.tflite'),
      });
      prefs = await SharedPreferences.getInstance();

      final lib = await openLibrary();

      expect(lib.models, hasLength(1));
      expect(lib.activeModel.isBuiltIn, isTrue);
    });

    test('runs only once', () async {
      final legacyModel = File(p.join(tmp.path, 'old.tflite'))
        ..writeAsBytesSync(<int>[1]);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'custom_model_path': legacyModel.path,
      });
      prefs = await SharedPreferences.getInstance();

      await openLibrary();
      final again = await openLibrary();

      expect(again.models, hasLength(2));
    });
  });
}
