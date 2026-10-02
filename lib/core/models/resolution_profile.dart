import 'package:flutter/foundation.dart';

@immutable
class ResolutionProfile {
  const ResolutionProfile({
    required this.id,
    required this.label,
    required this.size,
  });

  final String id;
  final String label;
  final int size;

  static const ResolutionProfile fast = ResolutionProfile(
    id: 'fast',
    label: 'Hızlı',
    size: 320,
  );

  static const ResolutionProfile balanced = ResolutionProfile(
    id: 'balanced',
    label: 'Dengeli',
    size: 416,
  );

  static const ResolutionProfile quality = ResolutionProfile(
    id: 'quality',
    label: 'Kalite',
    size: 640,
  );

  static const ResolutionProfile maxQuality = ResolutionProfile(
    id: 'max',
    label: 'Maksimum',
    size: 832,
  );

  static const List<ResolutionProfile> values = <ResolutionProfile>[
    fast,
    balanced,
    quality,
    maxQuality,
  ];

  static ResolutionProfile fromId(String? id) {
    assert(() {
      if (id != null && !values.any((p) => p.id == id)) {
        debugPrint('ResolutionProfile.fromId: unknown id "$id", defaulting to quality');
      }
      return true;
    }());
    return values.firstWhere(
      (profile) => profile.id == id,
      orElse: () => quality,
    );
  }

  String get displayLabel => '$label (${size}x$size)';
}
