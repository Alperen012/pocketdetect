import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_model.dart';
import '../models/model_review.dart';
import 'download_manager.dart';

/// Sorting options for the marketplace.
enum MarketplaceSort {
  newest,
  mostDownloaded,
  highestRated,
}

/// Service responsible for all marketplace API calls and state management.
class MarketplaceService extends ChangeNotifier implements DownloadRecorder {
  MarketplaceService(this._prefs) {
    _client = Supabase.instance.client;
    _loadCachedModels();
  }

  late final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const String _cacheKey = 'marketplace_models_cache';
  static const int _pageSize = 20;

  // ─── State ──────────────────────────────────────────────────
  List<MarketplaceModel> _models = [];
  List<MarketplaceModel> get models => _models;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  MarketplaceSort _sort = MarketplaceSort.newest;
  MarketplaceSort get sort => _sort;

  Set<String> _selectedTags = {};
  Set<String> get selectedTags => _selectedTags;

  double _minRating = 0;
  double get minRating => _minRating;

  // Cursor for pagination
  String? _cursorCreatedAt;

  // ─── Search debounce ───────────────────────────────────────
  Timer? _debounceTimer;

  void updateSearch(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });
  }

  void updateSort(MarketplaceSort sort) {
    _sort = sort;
    refresh();
  }

  void toggleTag(String tag) {
    final updated = Set<String>.from(_selectedTags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    _selectedTags = updated;
    refresh();
  }

  void updateMinRating(double rating) {
    _minRating = rating;
    refresh();
  }

  // ─── Data fetching ─────────────────────────────────────────

  /// Refresh the list from scratch.
  Future<void> refresh() async {
    _cursorCreatedAt = null;
    _hasMore = true;
    await _fetchModels(reset: true);
  }

  /// Load the next page (infinite scroll).
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _fetchModels(reset: false);
  }

  Future<void> _fetchModels({required bool reset}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var filter = _client
          .from('models')
          .select('*, model_tags(tag), profiles!models_user_id_fkey(username, avatar_url)')
          .eq('is_public', true)
          .eq('status', 'active');

      // Search filter
      if (_searchQuery.isNotEmpty) {
        filter = filter.or(
          'name.ilike.%$_searchQuery%,description.ilike.%$_searchQuery%',
        );
      }

      // Rating filter
      if (_minRating > 0) {
        filter = filter.gte('avg_rating', _minRating);
      }

      // Cursor-based pagination (applied before ordering)
      if (!reset && _cursorCreatedAt != null) {
        filter = filter.lt('created_at', _cursorCreatedAt!);
      }

      // Sorting + limit (transforms from filter → transform builder)
      final String orderColumn;
      switch (_sort) {
        case MarketplaceSort.newest:
          orderColumn = 'created_at';
        case MarketplaceSort.mostDownloaded:
          orderColumn = 'download_count';
        case MarketplaceSort.highestRated:
          orderColumn = 'avg_rating';
      }

      final data =
          await filter.order(orderColumn, ascending: false).limit(_pageSize);

      List<MarketplaceModel> fetched = (data as List<dynamic>)
          .map((dynamic e) =>
              MarketplaceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Tag filter (client-side since model_tags is a joined table)
      if (_selectedTags.isNotEmpty) {
        fetched = fetched
            .where((m) => _selectedTags.every((t) => m.tags.contains(t)))
            .toList();
      }

      // Check downloaded/favorited state
      fetched = await _enrichLocalState(fetched);

      if (reset) {
        _models = fetched;
      } else {
        _models = [..._models, ...fetched];
      }

      _hasMore = fetched.length >= _pageSize;

      if (fetched.isNotEmpty) {
        _cursorCreatedAt = fetched.last.createdAt.toUtc().toIso8601String();
      }

      // Cache first page
      if (reset && _models.isNotEmpty) {
        _cacheModels(_models);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('MarketplaceService error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single model by ID with full details.
  Future<MarketplaceModel?> fetchModelDetail(String modelId) async {
    try {
      final data = await _client
          .from('models')
          .select(
              '*, model_tags(tag), profiles!models_user_id_fkey(username, avatar_url)')
          .eq('id', modelId)
          .single();

      var model = MarketplaceModel.fromJson(data);
      final enriched = await _enrichLocalState([model]);
      return enriched.first;
    } catch (e) {
      debugPrint('fetchModelDetail error: $e');
      return null;
    }
  }

  // ─── Reviews ────────────────────────────────────────────────

  /// Fetch reviews for a model.
  Future<List<ModelReview>> fetchReviews(
    String modelId, {
    int limit = 20,
    String? cursorCreatedAt,
  }) async {
    try {
      var filter = _client
          .from('model_reviews')
          .select('*, profiles!model_reviews_user_id_fkey(username, avatar_url)')
          .eq('model_id', modelId);

      if (cursorCreatedAt != null) {
        filter = filter.lt('created_at', cursorCreatedAt);
      }

      final data =
          await filter.order('created_at', ascending: false).limit(limit);

      return (data as List<dynamic>)
          .map((dynamic e) =>
              ModelReview.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchReviews error: $e');
      return [];
    }
  }

  /// Submit a review for a model. User must have downloaded it.
  Future<String?> submitReview(
    String modelId,
    int rating, {
    String? reviewText,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 'Not authenticated';

      // Check if user has downloaded the model
      final downloads = await _client
          .from('model_downloads')
          .select('id')
          .eq('model_id', modelId)
          .eq('user_id', userId)
          .limit(1);

      if ((downloads as List<dynamic>).isEmpty) {
        return 'You must download this model before reviewing';
      }

      await _client.from('model_reviews').upsert({
        'model_id': modelId,
        'user_id': userId,
        'rating': rating,
        'review_text': reviewText,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Re-calculate avg_rating
      await _recalculateRating(modelId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _recalculateRating(String modelId) async {
    try {
      final result = await _client
          .from('model_reviews')
          .select('rating')
          .eq('model_id', modelId);

      final ratings = (result as List<dynamic>)
          .map((dynamic e) => (e as Map<String, dynamic>)['rating'] as int)
          .toList();

      if (ratings.isNotEmpty) {
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        await _client.from('models').update({
          'avg_rating': avg,
          'review_count': ratings.length,
        }).eq('id', modelId);
      }
    } catch (e) {
      debugPrint('_recalculateRating error: $e');
    }
  }

  // ─── Favorites ──────────────────────────────────────────────

  /// Toggle favorite status for a model.
  Future<bool> toggleFavorite(String modelId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final existing = await _client
          .from('model_favorites')
          .select()
          .eq('user_id', userId)
          .eq('model_id', modelId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('model_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('model_id', modelId);

        _updateModelInList(modelId, (m) => m.copyWith(isFavorited: false));
        return false; // removed
      } else {
        await _client.from('model_favorites').insert({
          'user_id': userId,
          'model_id': modelId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });

        _updateModelInList(modelId, (m) => m.copyWith(isFavorited: true));
        return true; // added
      }
    } catch (e) {
      debugPrint('toggleFavorite error: $e');
      return false;
    }
  }

  // ─── Publishing (Phase 2) ──────────────────────────────────

  /// Publish a model to the marketplace.
  Future<String?> publishModel({
    required String name,
    required String version,
    required String description,
    required String filePath,
    required int fileSizeBytes,
    required String licenseType,
    List<String> tags = const [],
    String? thumbnailPath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 'Not authenticated';

    try {
      final slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');

      // Upload model file to Supabase Storage (or R2 via edge function)
      final fileName = '${userId}_${slug}_v$version.tflite';
      final modelBytes = await _readFileBytes(filePath);

      await _client.storage.from('models').uploadBinary(
            fileName,
            modelBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final fileUrl =
          _client.storage.from('models').getPublicUrl(fileName);

      // Upload thumbnail if provided
      String? thumbnailUrl;
      if (thumbnailPath != null) {
        final thumbBytes = await _readFileBytes(thumbnailPath);
        final thumbName = '${userId}_${slug}_thumb.jpg';
        await _client.storage.from('thumbnails').uploadBinary(
              thumbName,
              thumbBytes,
              fileOptions: const FileOptions(upsert: true),
            );
        thumbnailUrl =
            _client.storage.from('thumbnails').getPublicUrl(thumbName);
      }

      // Insert model record
      await _client.from('models').insert({
        'user_id': userId,
        'name': name,
        'slug': slug,
        'version': version,
        'description': description,
        'thumbnail_url': thumbnailUrl,
        'file_url': fileUrl,
        'file_size_bytes': fileSizeBytes,
        'file_format': 'tflite',
        'license_type': licenseType,
        'is_public': true,
        'status': 'active',
        'download_count': 0,
        'avg_rating': 0,
        'review_count': 0,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Insert tags
      if (tags.isNotEmpty) {
        final lastModel = await _client
            .from('models')
            .select('id')
            .eq('slug', slug)
            .eq('user_id', userId)
            .single();

        final modelId = lastModel['id'] as String;
        for (final tag in tags) {
          await _client.from('model_tags').insert({
            'model_id': modelId,
            'tag': tag,
          });
        }
      }

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  Future<Uint8List> _readFileBytes(String path) async {
    return File(path).readAsBytes();
  }

  /// Fetch models published by the current user.
  Future<List<MarketplaceModel>> fetchMyModels() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _client
          .from('models')
          .select('*, model_tags(tag), profiles!models_user_id_fkey(username, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((dynamic e) =>
              MarketplaceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchMyModels error: $e');
      return [];
    }
  }

  /// Delete a model (only the owner can do this).
  Future<String?> deleteModel(String modelId) async {
    try {
      await _client.from('models').delete().eq('id', modelId);
      _models.removeWhere((m) => m.id == modelId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Record download ──────────────────────────────────────

  /// Record a download event and return a download URL.
  @override
  Future<String?> recordDownload(String modelId, String version) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Record download
      await _client.from('model_downloads').insert({
        'model_id': modelId,
        'user_id': userId,
        'version': version,
        'downloaded_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Increment download count
      await _client.rpc('increment_download_count', params: {
        'model_id_param': modelId,
      });

      // Update local state
      _updateModelInList(
        modelId,
        (m) => m.copyWith(
          downloadCount: m.downloadCount + 1,
          isDownloaded: true,
        ),
      );

      return null;
    } catch (e) {
      debugPrint('recordDownload error: $e');
      return e.toString();
    }
  }

  // ─── Local state helpers ───────────────────────────────────

  Future<List<MarketplaceModel>> _enrichLocalState(
    List<MarketplaceModel> models,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return models;

    try {
      // Get user's favorites
      final favorites = await _client
          .from('model_favorites')
          .select('model_id')
          .eq('user_id', userId);

      final favoriteIds = (favorites as List<dynamic>)
          .map((dynamic e) =>
              (e as Map<String, dynamic>)['model_id'] as String)
          .toSet();

      // Get user's downloads
      final downloads = await _client
          .from('model_downloads')
          .select('model_id')
          .eq('user_id', userId);

      final downloadedIds = (downloads as List<dynamic>)
          .map((dynamic e) =>
              (e as Map<String, dynamic>)['model_id'] as String)
          .toSet();

      // Get local download paths
      final localDownloads = _getDownloadedModelIds();

      return models.map((m) {
        return m.copyWith(
          isFavorited: favoriteIds.contains(m.id),
          isDownloaded:
              downloadedIds.contains(m.id) || localDownloads.contains(m.id),
        );
      }).toList();
    } catch (e) {
      return models;
    }
  }

  void _updateModelInList(
    String modelId,
    MarketplaceModel Function(MarketplaceModel) updater,
  ) {
    final idx = _models.indexWhere((m) => m.id == modelId);
    if (idx != -1) {
      _models[idx] = updater(_models[idx]);
      notifyListeners();
    }
  }

  // ─── Cache ─────────────────────────────────────────────────

  void _cacheModels(List<MarketplaceModel> models) {
    try {
      final jsonStr = jsonEncode(
        models.map((m) => m.toJson()).toList(),
      );
      _prefs.setString(_cacheKey, jsonStr);
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  void _loadCachedModels() {
    try {
      final cached = _prefs.getString(_cacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List<dynamic>;
        _models = list
            .map((dynamic e) =>
                MarketplaceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
  }

  // ─── Local downloads tracking ─────────────────────────────

  static const String _downloadedKey = 'marketplace_downloaded_models';

  Set<String> _getDownloadedModelIds() {
    final list = _prefs.getStringList(_downloadedKey);
    return list?.toSet() ?? {};
  }

  @override
  void markAsDownloaded(String modelId) {
    final ids = _getDownloadedModelIds();
    ids.add(modelId);
    _prefs.setStringList(_downloadedKey, ids.toList());
  }

  /// Available tags for filtering.
  static const List<String> availableTags = [
    'object-detection',
    'segmentation',
    'classification',
    'custom',
    'lightweight',
    'high-accuracy',
    'real-time',
    'indoor',
    'outdoor',
    'medical',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
