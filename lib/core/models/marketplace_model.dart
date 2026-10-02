import 'package:flutter/foundation.dart';

/// Represents a model listed on the AI Model Marketplace.
@immutable
class MarketplaceModel {
  const MarketplaceModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    required this.version,
    required this.description,
    this.thumbnailUrl,
    required this.fileUrl,
    required this.fileSizeBytes,
    required this.fileFormat,
    required this.licenseType,
    required this.isPublic,
    required this.status,
    required this.downloadCount,
    required this.avgRating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const <String>[],
    this.publisherName,
    this.publisherAvatarUrl,
    this.isFavorited = false,
    this.isDownloaded = false,
  });

  final String id;
  final String userId;
  final String name;
  final String slug;
  final String version;
  final String description;
  final String? thumbnailUrl;
  final String fileUrl;
  final int fileSizeBytes;
  final String fileFormat;
  final String licenseType;
  final bool isPublic;
  final String status; // 'pending', 'active', 'suspended'
  final int downloadCount;
  final double avgRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? publisherName;
  final String? publisherAvatarUrl;

  // Local state (not from server)
  final bool isFavorited;
  final bool isDownloaded;

  /// Human-readable file size.
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Whether this model is large (>500MB) and should warn about Wi-Fi.
  bool get isLargeFile => fileSizeBytes > 500 * 1024 * 1024;

  factory MarketplaceModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final tags = json['model_tags'] as List<dynamic>?;

    return MarketplaceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      fileUrl: json['file_url'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      fileFormat: json['file_format'] as String,
      licenseType: json['license_type'] as String,
      isPublic: json['is_public'] as bool,
      status: json['status'] as String,
      downloadCount: json['download_count'] as int,
      avgRating: (json['avg_rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tags: tags
              ?.map((dynamic e) =>
                  (e is Map<String, dynamic>) ? e['tag'] as String : e as String)
              .toList() ??
          const <String>[],
      publisherName: profile?['username'] as String?,
      publisherAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'slug': slug,
      'version': version,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'file_url': fileUrl,
      'file_size_bytes': fileSizeBytes,
      'file_format': fileFormat,
      'license_type': licenseType,
      'is_public': isPublic,
      'status': status,
      'download_count': downloadCount,
      'avg_rating': avgRating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MarketplaceModel copyWith({
    bool? isFavorited,
    bool? isDownloaded,
    int? downloadCount,
    double? avgRating,
    int? reviewCount,
  }) {
    return MarketplaceModel(
      id: id,
      userId: userId,
      name: name,
      slug: slug,
      version: version,
      description: description,
      thumbnailUrl: thumbnailUrl,
      fileUrl: fileUrl,
      fileSizeBytes: fileSizeBytes,
      fileFormat: fileFormat,
      licenseType: licenseType,
      isPublic: isPublic,
      status: status,
      downloadCount: downloadCount ?? this.downloadCount,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags: tags,
      publisherName: publisherName,
      publisherAvatarUrl: publisherAvatarUrl,
      isFavorited: isFavorited ?? this.isFavorited,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
