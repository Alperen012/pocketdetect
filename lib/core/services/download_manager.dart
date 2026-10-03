import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/download_state.dart';
import '../models/installed_model.dart';
import '../models/marketplace_model.dart';
import 'model_library_service.dart';
import 'model_validator.dart';

/// Fetches [url] into [savePath], reporting progress as `received, total`.
typedef FileDownloader =
    Future<void> Function(
      String url,
      String savePath, {
      CancelToken? cancelToken,
      void Function(int received, int total)? onProgress,
    });

/// What [DownloadManager] needs from the marketplace backend once a download
/// has succeeded. Implemented by `MarketplaceService`.
abstract interface class DownloadRecorder {
  Future<String?> recordDownload(String modelId, String version);
  void markAsDownloaded(String modelId);
}

/// Used when the marketplace is switched off: there is no backend to tell.
class NoopDownloadRecorder implements DownloadRecorder {
  const NoopDownloadRecorder();

  @override
  Future<String?> recordDownload(String modelId, String version) async => null;

  @override
  void markAsDownloaded(String modelId) {}
}

/// Downloads model files, validates them and installs them into the
/// [ModelLibraryService]. Progress and failures are tracked per key: the
/// marketplace model id, or the URL for direct imports.
class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required this.marketplaceService,
    required this.library,
    FileDownloader? downloader,
    Future<ModelValidationResult> Function(String path)? validator,
    Future<Directory> Function()? tempDir,
  }) : _validate = validator ?? ModelValidator.validate,
       _tempDir = tempDir ?? getTemporaryDirectory {
    if (downloader != null) {
      _download = downloader;
    } else {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      _dio = dio;
      _download = (url, savePath, {cancelToken, onProgress}) async {
        await dio.download(
          url,
          savePath,
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
        );
      };
    }
    library.addListener(notifyListeners);
  }

  final DownloadRecorder marketplaceService;
  final ModelLibraryService library;
  final Future<ModelValidationResult> Function(String path) _validate;
  final Future<Directory> Function() _tempDir;
  late final FileDownloader _download;
  Dio? _dio;

  // ─── State ──────────────────────────────────────────────────
  final Map<String, DownloadState> _downloads = {};
  Map<String, DownloadState> get downloads => Map.unmodifiable(_downloads);

  final Map<String, CancelToken> _cancelTokens = {};

  DownloadState? getDownloadState(String key) => _downloads[key];

  /// Marketplace models installed on this device.
  List<InstalledModel> get downloadedModels => library.models
      .where((m) => m.origin == InstalledModelOrigin.marketplace)
      .toList();

  bool isDownloaded(String marketplaceModelId) =>
      library.byMarketplaceId(marketplaceModelId) != null;

  String? getLocalPath(String marketplaceModelId) =>
      library.byMarketplaceId(marketplaceModelId)?.filePath;

  // ─── Marketplace download ──────────────────────────────────

  /// Download a marketplace model. Shows Wi-Fi warning for large files.
  Future<void> downloadModel(
    MarketplaceModel model, {
    VoidCallback? onWifiWarning,
  }) async {
    if (model.isLargeFile) {
      final connectivity = await Connectivity().checkConnectivity();
      final hasWifi = connectivity.any((r) => r == ConnectivityResult.wifi);
      if (!hasWifi && onWifiWarning != null) {
        onWifiWarning();
        return;
      }
    }

    final installed = await _downloadAndInstall(
      key: model.id,
      url: model.fileUrl,
      name: model.name,
      origin: InstalledModelOrigin.marketplace,
      marketplaceModelId: model.id,
      version: model.version,
    );

    // Count the download only once it actually succeeded.
    if (installed != null) {
      await marketplaceService.recordDownload(model.id, model.version);
      marketplaceService.markAsDownloaded(model.id);
    }
  }

  // ─── Direct URL import ─────────────────────────────────────

  /// Download a `.tflite` from [url] into the library. Returns the installed
  /// model, or null on failure (see [getDownloadState] with the URL as key).
  Future<InstalledModel?> importFromUrl(String url, {String? name}) {
    final uri = Uri.tryParse(url);
    final fileName = uri != null && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'model.tflite';
    return _downloadAndInstall(
      key: url,
      url: url,
      name: name ?? p.basenameWithoutExtension(fileName),
      origin: InstalledModelOrigin.url,
      sourceUrl: url,
    );
  }

  Future<InstalledModel?> _downloadAndInstall({
    required String key,
    required String url,
    required String name,
    required InstalledModelOrigin origin,
    String? marketplaceModelId,
    String? version,
    String? sourceUrl,
  }) async {
    if (_downloads[key]?.isDownloading == true) return null;

    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;
    _downloads[key] = DownloadState(
      modelId: key,
      status: DownloadStatus.downloading,
    );
    notifyListeners();

    File? temp;
    try {
      final dir = await _tempDir();
      await dir.create(recursive: true);
      temp = File(
        p.join(
          dir.path,
          'download_${DateTime.now().microsecondsSinceEpoch}.tflite',
        ),
      );

      await _download(
        url,
        temp.path,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          final current = _downloads[key];
          if (current == null) return;
          _downloads[key] = current.copyWith(
            progress: total > 0 ? received / total : 0.0,
          );
          notifyListeners();
        },
      );

      _downloads[key] = _downloads[key]!.copyWith(
        status: DownloadStatus.validating,
      );
      notifyListeners();

      final validation = await _validate(temp.path);
      if (!validation.isValid) {
        _downloads[key] = _downloads[key]!.copyWith(
          status: DownloadStatus.failed,
          error: 'Model validation failed: ${validation.errorCode?.name}',
        );
        notifyListeners();
        return null;
      }

      final installed = await library.installFile(
        sourcePath: temp.path,
        name: name,
        validation: validation,
        // Downloads carry no label file: assume COCO only for 80-class models,
        // otherwise fall back to generic class_N names rather than mislabel.
        usesCocoLabels: validation.classCount == 80,
        origin: origin,
        sourceUrl: sourceUrl,
        marketplaceModelId: marketplaceModelId,
        version: version,
      );

      _downloads[key] = DownloadState(
        modelId: key,
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: installed.filePath,
      );
      notifyListeners();
      return installed;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _downloads.remove(key);
      } else {
        _downloads[key] =
            (_downloads[key] ??
                    DownloadState(modelId: key, status: DownloadStatus.failed))
                .copyWith(
                  status: DownloadStatus.failed,
                  error: e.message ?? 'Download failed',
                );
      }
      notifyListeners();
      return null;
    } catch (e) {
      _downloads[key] =
          (_downloads[key] ??
                  DownloadState(modelId: key, status: DownloadStatus.failed))
              .copyWith(status: DownloadStatus.failed, error: e.toString());
      notifyListeners();
      return null;
    } finally {
      _cancelTokens.remove(key);
      try {
        if (temp != null && await temp.exists()) await temp.delete();
      } catch (_) {}
    }
  }

  /// Cancel an active download.
  void cancelDownload(String key) {
    _cancelTokens[key]?.cancel();
    _cancelTokens.remove(key);
    _downloads.remove(key);
    notifyListeners();
  }

  // ─── Library actions for marketplace models ────────────────

  /// Make a downloaded marketplace model the active one.
  Future<void> activateModel(String marketplaceModelId) async {
    final model = library.byMarketplaceId(marketplaceModelId);
    if (model == null) return;
    await library.activate(model.id);
  }

  /// Delete a downloaded marketplace model from the device.
  Future<void> deleteDownloadedModel(String marketplaceModelId) async {
    final model = library.byMarketplaceId(marketplaceModelId);
    if (model != null) {
      await library.remove(model.id);
    }
    _downloads.remove(marketplaceModelId);
    notifyListeners();
  }

  @override
  void dispose() {
    library.removeListener(notifyListeners);
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _dio?.close();
    super.dispose();
  }
}
