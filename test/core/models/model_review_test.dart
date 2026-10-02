import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/models/model_review.dart';

void main() {
  Map<String, dynamic> fullJson() {
    return {
      'id': 'review-1',
      'model_id': 'model-1',
      'user_id': 'user-1',
      'rating': 5,
      'review_text': 'Excellent model!',
      'created_at': '2026-02-15T10:30:00.000Z',
      'profiles': {
        'username': 'reviewer_a',
        'avatar_url': 'https://example.com/avatar.png',
      },
    };
  }

  group('ModelReview', () {
    test('fromJson() parses all fields with profile', () {
      final review = ModelReview.fromJson(fullJson());

      expect(review.id, 'review-1');
      expect(review.modelId, 'model-1');
      expect(review.userId, 'user-1');
      expect(review.rating, 5);
      expect(review.reviewText, 'Excellent model!');
      expect(review.createdAt, DateTime.utc(2026, 2, 15, 10, 30));
      expect(review.username, 'reviewer_a');
      expect(review.avatarUrl, 'https://example.com/avatar.png');
    });

    test('fromJson() handles missing profile', () {
      final json = fullJson();
      json.remove('profiles');
      final review = ModelReview.fromJson(json);

      expect(review.username, isNull);
      expect(review.avatarUrl, isNull);
    });

    test('fromJson() handles null review_text', () {
      final json = fullJson();
      json['review_text'] = null;
      final review = ModelReview.fromJson(json);

      expect(review.reviewText, isNull);
    });

    test('toJson() includes only model_id, rating, review_text', () {
      final review = ModelReview.fromJson(fullJson());
      final json = review.toJson();

      expect(json.keys, containsAll(['model_id', 'rating', 'review_text']));
      expect(json['model_id'], 'model-1');
      expect(json['rating'], 5);
      expect(json['review_text'], 'Excellent model!');
      // Should NOT include id, user_id, created_at, etc.
      expect(json.containsKey('id'), false);
      expect(json.containsKey('user_id'), false);
      expect(json.containsKey('created_at'), false);
    });
  });
}
