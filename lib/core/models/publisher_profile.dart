import 'package:flutter/foundation.dart';

/// A user profile in the marketplace.
@immutable
class PublisherProfile {
  const PublisherProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.modelCount = 0,
    this.totalDownloads = 0,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final int modelCount;
  final int totalDownloads;

  factory PublisherProfile.fromJson(Map<String, dynamic> json) {
    return PublisherProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      modelCount: json['model_count'] as int? ?? 0,
      totalDownloads: json['total_downloads'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
