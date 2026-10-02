import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/download_state.dart';
import '../models/marketplace_model.dart';
import '../services/marketplace_service.dart';
import '../services/model_validator.dart';
import '../services/settings_controller.dart';

/// Manages model file downloads with progress tracking and validation.
class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required this.marketplaceService,
    required this.settingsController,
    required SharedPreferences prefs,
  }) : _prefs = prefs {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
    ));
    _loadDownloadedModels();
  }

  final MarketplaceService marketplaceService;
  final SettingsController settingsController;
  final SharedPreferences _prefs;
  late final Dio _dio;

  static const String _downloadedModelsKey = 'downloaded_models_metadata';

  // ─── State ──────────────────────────────────────────────────
  final Map<String, DownloadState> _downloads = {};
  Map<String, DownloadState> get downloads => Map.unmodifiable(_downloads);

  final Map<String, CancelToken> _cancelTokens = {};

  /// Metadata of downloaded models (persisted).
  final Map<String, DownloadedModelMeta> _downloadedModels = {};

  DownloadState? getDownloadState(String modelId) => _downloads[modelId];

  bool isDownloaded(String modelId) => _downloadedModels.containsKey(modelId);

  String? getLocalPath(String modelId) => _downloadedModels[modelId]?.localPath;

  List<DownloadedModelMeta> get downloadedModels =>
      _downloadedModels.values.toList();

  // ─── Download ──────────────────────────────────────────────

  /// Download a model file. Shows Wi-Fi warning for large files.
  Future<void> downloadModel(
    MarketplaceModel model, {
    VoidCallback? onWifiWarning,
  }) async {
    // Check file size and connection
    if (model.isLargeFile) {
      final connectivity = await Connectivity().checkConnectivity();
      final hasWifi =
          connectivity.any((r) => r == ConnectivityResult.wifi);
      if (!hasWifi && onWifiWarning != null) {
        onWifiWarning();
        return;
      }
    }

    // Check if already downloading
    if (_downloads[model.id]?.isDownloading == true) return;

    final cancelToken = CancelToken();
    _cancelTokens[model.id] = cancelToken;

    _downloads[model.id] = DownloadState(
      modelId: model.id,
      status: DownloadStatus.downloading,
    );
    notifyListeners();

    try {
      // Record download on server
      await marketplaceService.recordDownload(model.id, model.version);
      marketplaceService.markAsDownloaded(model.id);

      // Get destination path
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir =
          Directory(p.join(appDir.path, 'marketplace_models'));
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final fileName =
          '${model.slug}_v${model.version}.tflite';
      final destPath = p.join(modelsDir.path, fileName);

      // Download file
      await _dio.download(
        model.fileUrl,
        destPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          _downloads[model.id] = _downloads[model.id]!.copyWith(
            progress: progress,
          );
          notifyListeners();
        },
      );

      // Validate downloaded file
      _downloads[model.id] = _downloads[model.id]!.copyWith(
        status: DownloadStatus.validating,
      );
      notifyListeners();

      final validationResult = await ModelValidator.validate(destPath);
      if (!validationResult.isValid) {
        // Delete invalid file
        final file = File(destPath);
        if (await file.exists()) await file.delete();

        _downloads[model.id] = _downloads[model.id]!.copyWith(
          status: DownloadStatus.failed,
          error: 'Model validation failed: ${validationResult.errorCode?.name}',
        );
        notifyListeners();
        return;
      }

      // Save metadata
      final meta = DownloadedModelMeta(
        modelId: model.id,
        name: model.name,
        version: model.version,
        localPath: destPath,
        fileSizeBytes: model.fileSizeBytes,
        downloadedAt: DateTime.now(),
        inputWidth: validationResult.inputWidth!,
        inputHeight: validationResult.inputHeight!,
        classCount: validationResult.classCount!,
        quantType: validationResult.inputType!,
      );

      _downloadedModels[model.id] = meta;
      _saveDownloadedModels();

      _downloads[model.id] = DownloadState(
        modelId: model.id,
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: destPath,
      );
      notifyListeners();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _downloads.remove(model.id);
      } else {
        _downloads[model.id] = _downloads[model.id]!.copyWith(
          status: DownloadStatus.failed,
          error: e.message ?? 'Download failed',
        );
      }
      notifyListeners();
    } catch (e) {
      _downloads[model.id] = _downloads[model.id]?.copyWith(
            status: DownloadStatus.failed,
            error: e.toString(),
          ) ??
          DownloadState(
            modelId: model.id,
            status: DownloadStatus.failed,
            error: e.toString(),
          );
      notifyListeners();
    } finally {
      _cancelTokens.remove(model.id);
    }
  }

  /// Cancel an active download.
  void cancelDownload(String modelId) {
    _cancelTokens[modelId]?.cancel();
    _cancelTokens.remove(modelId);
    _downloads.remove(modelId);
    notifyListeners();
  }

  // ─── Activate model ────────────────────────────────────────

  /// Activate a downloaded marketplace model for use in detection.
  /// Uses the same SettingsController API as the import wizard.
  void activateModel(String modelId) {
    final meta = _downloadedModels[modelId];
    if (meta == null) return;

    settingsController.updateCustomModelPath(meta.localPath);
    settingsController.updateCustomLabelsPath(null); // Use COCO defaults
    settingsController.updateCustomModelMetadata(
      name: meta.name,
      inputWidth: meta.inputWidth,
      inputHeight: meta.inputHeight,
      classCount: meta.classCount,
      quantType: meta.quantType,
    );
    settingsController.updateUseCustomModel(true);
  }

  // ─── Delete downloaded model ───────────────────────────────

  /// Delete a downloaded model file from the device.
  Future<void> deleteDownloadedModel(String modelId) async {
    final meta = _downloadedModels[modelId];
    if (meta != null) {
      final file = File(meta.localPath);
      if (await file.exists()) {
        await file.delete();
      }
      _downloadedModels.remove(modelId);
      _downloads.remove(modelId);
      _saveDownloadedModels();
      notifyListeners();
    }
  }

  // ─── Persistence ───────────────────────────────────────────

  void _saveDownloadedModels() {
    final entries = _downloadedModels.values.map((m) => m.toJson()).toList();
    _prefs.setString(
      _downloadedModelsKey,
      entries.map((e) => _encodeJson(e)).join('|||'),
    );
  }

  void _loadDownloadedModels() {
    final raw = _prefs.getString(_downloadedModelsKey);
    if (raw == null || raw.isEmpty) return;

    for (final part in raw.split('|||')) {
      try {
        final json = _decodeJson(part);
        final meta = DownloadedModelMeta.fromJson(json);
        _downloadedModels[meta.modelId] = meta;
        // Also set completed download state
        _downloads[meta.modelId] = DownloadState(
          modelId: meta.modelId,
          status: DownloadStatus.completed,
          progress: 1.0,
          localPath: meta.localPath,
        );
      } catch (_) {
        // Skip corrupted entries
      }
    }
  }

  String _encodeJson(Map<String, dynamic> json) {
    // Simple encoding: key=value pairs separated by ';'
    return json.entries.map((e) => '${e.key}=${e.value}').join(';');
  }

  Map<String, dynamic> _decodeJson(String encoded) {
    final map = <String, dynamic>{};
    for (final pair in encoded.split(';')) {
      final idx = pair.indexOf('=');
      if (idx > 0) {
        map[pair.substring(0, idx)] = pair.substring(idx + 1);
      }
    }
    return map;
  }

  @override
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _dio.close();
    super.dispose();
  }
}

/// Metadata about a downloaded model, persisted locally.
class DownloadedModelMeta {
  const DownloadedModelMeta({
    required this.modelId,
    required this.name,
    required this.version,
    required this.localPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.inputWidth,
    required this.inputHeight,
    required this.classCount,
    required this.quantType,
  });

  final String modelId;
  final String name;
  final String version;
  final String localPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final int inputWidth;
  final int inputHeight;
  final int classCount;
  final String quantType;

  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'name': name,
        'version': version,
        'localPath': localPath,
        'fileSizeBytes': fileSizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
        'inputWidth': inputWidth,
        'inputHeight': inputHeight,
        'classCount': classCount,
        'quantType': quantType,
      };

  factory DownloadedModelMeta.fromJson(Map<String, dynamic> json) {
    return DownloadedModelMeta(
      modelId: json['modelId'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      localPath: json['localPath'] as String,
      fileSizeBytes: int.tryParse(json['fileSizeBytes'].toString()) ?? 0,
      downloadedAt: DateTime.tryParse(json['downloadedAt'].toString()) ??
          DateTime.now(),
      inputWidth: int.tryParse(json['inputWidth'].toString()) ?? 0,
      inputHeight: int.tryParse(json['inputHeight'].toString()) ?? 0,
      classCount: int.tryParse(json['classCount'].toString()) ?? 0,
      quantType: json['quantType'] as String? ?? 'FLOAT32',
    );
  }
}
