import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/models/marketplace_model.dart';

void main() {
  Map<String, dynamic> sampleJson({
    String id = 'model-1',
    int fileSizeBytes = 1024 * 1024 * 10, // 10 MB
    int downloadCount = 42,
    double avgRating = 4.5,
  }) {
    return {
      'id': id,
      'user_id': 'user-1',
      'name': 'Test Model',
      'slug': 'test-model',
      'version': '1.0.0',
      'description': 'A test model for unit tests.',
      'thumbnail_url': null,
      'file_url': 'https://example.com/model.tflite',
      'file_size_bytes': fileSizeBytes,
      'file_format': 'tflite',
      'license_type': 'MIT',
      'is_public': true,
      'status': 'active',
      'download_count': downloadCount,
      'avg_rating': avgRating,
      'review_count': 5,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-03-01T00:00:00.000Z',
      'model_tags': [
        {'tag': 'object-detection'},
        {'tag': 'yolo'},
      ],
      'profiles': {
        'username': 'test_publisher',
        'avatar_url': null,
      },
    };
  }

  group('MarketplaceModel', () {
    test('fromJson() parses all fields correctly', () {
      final model = MarketplaceModel.fromJson(sampleJson());

      expect(model.id, 'model-1');
      expect(model.userId, 'user-1');
      expect(model.name, 'Test Model');
      expect(model.slug, 'test-model');
      expect(model.version, '1.0.0');
      expect(model.description, 'A test model for unit tests.');
      expect(model.fileUrl, 'https://example.com/model.tflite');
      expect(model.fileSizeBytes, 10 * 1024 * 1024);
      expect(model.fileFormat, 'tflite');
      expect(model.licenseType, 'MIT');
      expect(model.isPublic, true);
      expect(model.status, 'active');
      expect(model.downloadCount, 42);
      expect(model.avgRating, 4.5);
      expect(model.reviewCount, 5);
      expect(model.tags, ['object-detection', 'yolo']);
      expect(model.publisherName, 'test_publisher');
      expect(model.isFavorited, false);
      expect(model.isDownloaded, false);
    });

    test('fromJson() handles missing profiles gracefully', () {
      final json = sampleJson();
      json.remove('profiles');
      final model = MarketplaceModel.fromJson(json);

      expect(model.publisherName, isNull);
      expect(model.publisherAvatarUrl, isNull);
    });

    test('fromJson() handles missing model_tags gracefully', () {
      final json = sampleJson();
      json.remove('model_tags');
      final model = MarketplaceModel.fromJson(json);

      expect(model.tags, isEmpty);
    });

    test('toJson() produces expected map', () {
      final model = MarketplaceModel.fromJson(sampleJson());
      final json = model.toJson();

      expect(json['id'], 'model-1');
      expect(json['name'], 'Test Model');
      expect(json['file_size_bytes'], 10 * 1024 * 1024);
    });

    test('fileSizeFormatted returns bytes for small files', () {
      final model = MarketplaceModel.fromJson(
        sampleJson(fileSizeBytes: 512),
      );
      expect(model.fileSizeFormatted, '512 B');
    });

    test('fileSizeFormatted returns KB for medium files', () {
      final model = MarketplaceModel.fromJson(
        sampleJson(fileSizeBytes: 2048),
      );
      expect(model.fileSizeFormatted, '2.0 KB');
    });

    test('fileSizeFormatted returns MB for large files', () {
      final model = MarketplaceModel.fromJson(
        sampleJson(fileSizeBytes: 5 * 1024 * 1024),
      );
      expect(model.fileSizeFormatted, '5.0 MB');
    });

    test('isLargeFile returns true for >500MB', () {
      final large = MarketplaceModel.fromJson(
        sampleJson(fileSizeBytes: 600 * 1024 * 1024),
      );
      expect(large.isLargeFile, true);

      final small = MarketplaceModel.fromJson(
        sampleJson(fileSizeBytes: 400 * 1024 * 1024),
      );
      expect(small.isLargeFile, false);
    });

    test('copyWith() preserves unchanged fields', () {
      final model = MarketplaceModel.fromJson(sampleJson());
      final updated = model.copyWith(isFavorited: true, downloadCount: 100);

      expect(updated.isFavorited, true);
      expect(updated.downloadCount, 100);
      // Unchanged
      expect(updated.id, model.id);
      expect(updated.name, model.name);
      expect(updated.avgRating, model.avgRating);
      expect(updated.isDownloaded, model.isDownloaded);
    });
  });
}
