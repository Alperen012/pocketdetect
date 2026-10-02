import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/models/download_state.dart';
import 'package:mobile_yolo/core/models/installed_model.dart';
import 'package:mobile_yolo/core/models/marketplace_model.dart';
import 'package:mobile_yolo/core/services/download_manager.dart';
import 'package:mobile_yolo/core/services/model_library_service.dart';
import 'package:mobile_yolo/core/services/model_validator.dart';

class FakeRecorder implements DownloadRecorder {
  final List<(String, String)> recorded = <(String, String)>[];
  final List<String> marked = <String>[];

  @override
  Future<String?> recordDownload(String modelId, String version) async {
    recorded.add((modelId, version));
    return null;
  }

  @override
  void markAsDownloaded(String modelId) => marked.add(modelId);
}

ModelValidationResult valid({int classes = 3}) => ModelValidationResult.success(
      inputWidth: 640,
      inputHeight: 640,
      inputType: 'INT8',
      outputShape: <int>[1, 4 + classes, 8400],
      classCount: classes,
    );

MarketplaceModel marketplaceModel() => MarketplaceModel(
      id: 'mp-1',
      userId: 'u1',
      name: 'Helmets',
      slug: 'helmets',
      version: '2.0.0',
      description: 'd',
      fileUrl: 'https://example.com/helmets.tflite',
      fileSizeBytes: 1024,
      fileFormat: 'tflite',
      licenseType: 'MIT',
      isPublic: true,
      status: 'active',
      downloadCount: 0,
      avgRating: 0,
      reviewCount: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late Directory tmp;
  late ModelLibraryService library;
  late FakeRecorder recorder;
  late List<String> tempFilesSeen;

  Future<void> okDownloader(
    String url,
    String savePath, {
    CancelToken? cancelToken,
    void Function(int, int)? onProgress,
  }) async {
    tempFilesSeen.add(savePath);
    onProgress?.call(50, 100);
    await File(savePath).writeAsBytes(<int>[1, 2, 3]);
    onProgress?.call(100, 100);
  }

  DownloadManager manager({
    FileDownloader? downloader,
    Future<ModelValidationResult> Function(String)? validator,
  }) {
    return DownloadManager(
      marketplaceService: recorder,
      library: library,
      downloader: downloader ?? okDownloader,
      validator: validator ?? (_) async => valid(),
      tempDir: () async => Directory(p.join(tmp.path, 'dl')),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    tmp = await Directory.systemTemp.createTemp('download_manager_test');
    var n = 0;
    library = await ModelLibraryService.create(
      prefs,
      modelsDir: () async => Directory(p.join(tmp.path, 'library')),
      idGenerator: () => 'id${++n}',
    );
    recorder = FakeRecorder();
    tempFilesSeen = <String>[];
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('importFromUrl', () {
    test('installs the model, names it from the URL and cleans up', () async {
      final dm = manager();

      final model =
          await dm.importFromUrl('https://example.com/models/vests.tflite');

      expect(model, isNotNull);
      expect(model!.name, 'vests');
      expect(model.origin, InstalledModelOrigin.url);
      expect(model.sourceUrl, 'https://example.com/models/vests.tflite');
      expect(model.labels, <String>['class_0', 'class_1', 'class_2']);
      expect(library.models, hasLength(2));
      expect(
        dm.getDownloadState('https://example.com/models/vests.tflite')!.status,
        DownloadStatus.completed,
      );
      expect(File(tempFilesSeen.single).existsSync(), isFalse);
      expect(recorder.recorded, isEmpty, reason: 'URL imports are not counted');
    });

    test('assumes COCO names only for 80-class models', () async {
      final dm = manager(validator: (_) async => valid(classes: 80));

      final model = await dm.importFromUrl('https://example.com/coco.tflite');

      expect(model!.usesCocoLabels, isTrue);
      expect(model.labels, isEmpty);
    });

    test('a model that fails validation is not installed', () async {
      final dm = manager(
        validator: (_) async => const ModelValidationResult.failure(
          ModelValidationError.unsupportedOutputShape,
        ),
      );

      final model = await dm.importFromUrl('https://example.com/bad.tflite');

      expect(model, isNull);
      expect(library.models, hasLength(1));
      final state = dm.getDownloadState('https://example.com/bad.tflite')!;
      expect(state.status, DownloadStatus.failed);
      expect(state.error, contains('unsupportedOutputShape'));
      expect(File(tempFilesSeen.single).existsSync(), isFalse);
    });

    test('a failing download is reported and leaves nothing behind', () async {
      final dm = manager(
        downloader: (url, savePath, {cancelToken, onProgress}) async {
          tempFilesSeen.add(savePath);
          await File(savePath).writeAsBytes(<int>[1]);
          throw const SocketException('offline');
        },
      );

      final model = await dm.importFromUrl('https://example.com/x.tflite');

      expect(model, isNull);
      expect(library.models, hasLength(1));
      final state = dm.getDownloadState('https://example.com/x.tflite')!;
      expect(state.status, DownloadStatus.failed);
      expect(state.error, contains('offline'));
      expect(File(tempFilesSeen.single).existsSync(), isFalse);
    });

    test('reports progress while downloading', () async {
      final dm = manager();
      final progress = <double>[];
      dm.addListener(() {
        final s = dm.getDownloadState('https://example.com/p.tflite');
        if (s != null && s.isDownloading) progress.add(s.progress);
      });

      await dm.importFromUrl('https://example.com/p.tflite');

      expect(progress, containsAllInOrder(<double>[0.5, 1.0]));
    });

    test('ignores a second request for a URL that is already downloading',
        () async {
      final gate = Completer<void>();
      final dm = manager(
        downloader: (url, savePath, {cancelToken, onProgress}) async {
          await gate.future;
          await File(savePath).writeAsBytes(<int>[1]);
        },
      );

      final first = dm.importFromUrl('https://example.com/slow.tflite');
      await Future<void>.delayed(Duration.zero);
      final second = await dm.importFromUrl('https://example.com/slow.tflite');
      gate.complete();

      expect(second, isNull);
      expect(await first, isNotNull);
      expect(library.models, hasLength(2));
    });
  });

  group('marketplace downloads', () {
    test('records the download only after it succeeded', () async {
      final dm = manager();

      await dm.downloadModel(marketplaceModel());

      expect(recorder.recorded, <(String, String)>[('mp-1', '2.0.0')]);
      expect(recorder.marked, <String>['mp-1']);
      expect(dm.isDownloaded('mp-1'), isTrue);
      final installed = library.byMarketplaceId('mp-1')!;
      expect(installed.origin, InstalledModelOrigin.marketplace);
      expect(installed.version, '2.0.0');
      expect(dm.getLocalPath('mp-1'), installed.filePath);
      expect(dm.downloadedModels.map((m) => m.id), <String>[installed.id]);
    });

    test('does not count a failed download', () async {
      final dm = manager(
        downloader: (url, savePath, {cancelToken, onProgress}) async =>
            throw const SocketException('offline'),
      );

      await dm.downloadModel(marketplaceModel());

      expect(recorder.recorded, isEmpty);
      expect(recorder.marked, isEmpty);
      expect(dm.isDownloaded('mp-1'), isFalse);
      expect(dm.getDownloadState('mp-1')!.status, DownloadStatus.failed);
    });

    test('activateModel makes the downloaded model active', () async {
      final dm = manager();
      await dm.downloadModel(marketplaceModel());

      await dm.activateModel('mp-1');

      expect(library.activeModel.marketplaceModelId, 'mp-1');
    });

    test('deleteDownloadedModel removes it and falls back to built-in',
        () async {
      final dm = manager();
      await dm.downloadModel(marketplaceModel());
      await dm.activateModel('mp-1');
      final path = dm.getLocalPath('mp-1')!;

      await dm.deleteDownloadedModel('mp-1');

      expect(dm.isDownloaded('mp-1'), isFalse);
      expect(dm.getDownloadState('mp-1'), isNull);
      expect(library.activeModel.isBuiltIn, isTrue);
      expect(File(path).existsSync(), isFalse);
    });

    test('forwards library changes to its listeners', () async {
      final dm = manager();
      var notified = 0;
      dm.addListener(() => notified++);

      await library.activate(InstalledModel.builtInId); // no change
      final before = notified;
      await dm.downloadModel(marketplaceModel());

      expect(notified, greaterThan(before));
    });
  });
}
