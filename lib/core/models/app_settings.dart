import 'package:flutter/foundation.dart';

import 'resolution_profile.dart';

@immutable
class AppSettings {
  const AppSettings({
    required this.modelId,
    required this.useCustomModel,
    required this.customModelPath,
    required this.customLabelsPath,
    required this.resolutionProfile,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.useNms,
    required this.maxDetections,
    required this.lowMemoryWarningSeen,
    this.customModelName,
    this.customModelInputWidth,
    this.customModelInputHeight,
    this.customModelClassCount,
    this.customModelQuantType,
  });

  final String modelId;
  final bool useCustomModel;
  final String? customModelPath;
  final String? customLabelsPath;
  final ResolutionProfile resolutionProfile;
  final double confidenceThreshold;
  final double iouThreshold;
  final bool useNms;
  final int maxDetections;
  final bool lowMemoryWarningSeen;

  // Custom model metadata (populated during import wizard).
  final String? customModelName;
  final int? customModelInputWidth;
  final int? customModelInputHeight;
  final int? customModelClassCount;
  final String? customModelQuantType;

  AppSettings copyWith({
    String? modelId,
    bool? useCustomModel,
    String? customModelPath,
    bool clearCustomModelPath = false,
    String? customLabelsPath,
    bool clearCustomLabelsPath = false,
    ResolutionProfile? resolutionProfile,
    double? confidenceThreshold,
    double? iouThreshold,
    bool? useNms,
    int? maxDetections,
    bool? lowMemoryWarningSeen,
    String? customModelName,
    bool clearCustomModelName = false,
    int? customModelInputWidth,
    bool clearCustomModelInputWidth = false,
    int? customModelInputHeight,
    bool clearCustomModelInputHeight = false,
    int? customModelClassCount,
    bool clearCustomModelClassCount = false,
    String? customModelQuantType,
    bool clearCustomModelQuantType = false,
  }) {
    return AppSettings(
      modelId: modelId ?? this.modelId,
      useCustomModel: useCustomModel ?? this.useCustomModel,
      customModelPath: clearCustomModelPath ? null : (customModelPath ?? this.customModelPath),
      customLabelsPath: clearCustomLabelsPath ? null : (customLabelsPath ?? this.customLabelsPath),
      resolutionProfile: resolutionProfile ?? this.resolutionProfile,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      iouThreshold: iouThreshold ?? this.iouThreshold,
      useNms: useNms ?? this.useNms,
      maxDetections: maxDetections ?? this.maxDetections,
      lowMemoryWarningSeen: lowMemoryWarningSeen ?? this.lowMemoryWarningSeen,
      customModelName: clearCustomModelName ? null : (customModelName ?? this.customModelName),
      customModelInputWidth: clearCustomModelInputWidth ? null : (customModelInputWidth ?? this.customModelInputWidth),
      customModelInputHeight: clearCustomModelInputHeight ? null : (customModelInputHeight ?? this.customModelInputHeight),
      customModelClassCount: clearCustomModelClassCount ? null : (customModelClassCount ?? this.customModelClassCount),
      customModelQuantType: clearCustomModelQuantType ? null : (customModelQuantType ?? this.customModelQuantType),
    );
  }

  static const AppSettings defaults = AppSettings(
    modelId: 'yolo26_nano',
    useCustomModel: false,
    customModelPath: null,
    customLabelsPath: null,
    resolutionProfile: ResolutionProfile.quality,
    confidenceThreshold: 0.5,
    iouThreshold: 0.45,
    useNms: true,
    maxDetections: 100,
    lowMemoryWarningSeen: false,
  );
}
