import 'package:flutter/foundation.dart';

/// Represents the state of a model download.
@immutable
class DownloadState {
  const DownloadState({
    required this.modelId,
    required this.status,
    this.progress = 0.0,
    this.localPath,
    this.error,
  });

  final String modelId;
  final DownloadStatus status;

  /// Progress from 0.0 to 1.0
  final double progress;

  /// Path to the downloaded file on device
  final String? localPath;

  /// Error message if download failed
  final String? error;

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? localPath,
    String? error,
  }) {
    return DownloadState(
      modelId: modelId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
    );
  }
}

enum DownloadStatus {
  idle,
  downloading,
  validating,
  completed,
  failed,
}
