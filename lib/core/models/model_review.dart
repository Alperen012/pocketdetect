import 'package:flutter/foundation.dart';

/// A review/rating for a marketplace model.
@immutable
class ModelReview {
  const ModelReview({
    required this.id,
    required this.modelId,
    required this.userId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String modelId;
  final String userId;
  final int rating; // 1–5
  final String? reviewText;
  final DateTime createdAt;
  final String? username;
  final String? avatarUrl;

  factory ModelReview.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ModelReview(
      id: json['id'] as String,
      modelId: json['model_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'model_id': modelId,
      'rating': rating,
      'review_text': reviewText,
    };
  }
}
