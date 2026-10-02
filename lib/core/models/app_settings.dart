import 'package:flutter/foundation.dart';

import 'resolution_profile.dart';

/// Detection tuning and UI flags. Which model runs is not a setting; it is
/// owned by `ModelLibraryService`.
@immutable
class AppSettings {
  const AppSettings({
    required this.resolutionProfile,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.useNms,
    required this.maxDetections,
    required this.lowMemoryWarningSeen,
  });

  final ResolutionProfile resolutionProfile;
  final double confidenceThreshold;
  final double iouThreshold;
  final bool useNms;
  final int maxDetections;
  final bool lowMemoryWarningSeen;

  AppSettings copyWith({
    ResolutionProfile? resolutionProfile,
    double? confidenceThreshold,
    double? iouThreshold,
    bool? useNms,
    int? maxDetections,
    bool? lowMemoryWarningSeen,
  }) {
    return AppSettings(
      resolutionProfile: resolutionProfile ?? this.resolutionProfile,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      iouThreshold: iouThreshold ?? this.iouThreshold,
      useNms: useNms ?? this.useNms,
      maxDetections: maxDetections ?? this.maxDetections,
      lowMemoryWarningSeen: lowMemoryWarningSeen ?? this.lowMemoryWarningSeen,
    );
  }

  static const AppSettings defaults = AppSettings(
    resolutionProfile: ResolutionProfile.quality,
    confidenceThreshold: 0.5,
    iouThreshold: 0.45,
    useNms: true,
    maxDetections: 100,
    lowMemoryWarningSeen: false,
  );
}
