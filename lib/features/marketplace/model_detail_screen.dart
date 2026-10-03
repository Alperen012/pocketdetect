import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/models/download_state.dart';
import '../../core/models/marketplace_model.dart';
import '../../core/models/model_review.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/download_manager.dart';
import '../../core/services/marketplace_service.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

/// Detail screen for a specific marketplace model. Shows metadata, reviews,
/// and a download/activate button.
class ModelDetailScreen extends StatefulWidget {
  const ModelDetailScreen({super.key, required this.modelId});

  final String modelId;

  @override
  State<ModelDetailScreen> createState() => _ModelDetailScreenState();
}

class _ModelDetailScreenState extends State<ModelDetailScreen> {
  MarketplaceModel? _model;
  List<ModelReview> _reviews = [];
  bool _isLoading = true;
  String? _error;

  // Review form
  final _reviewController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final svc = context.read<MarketplaceService>();
      final results = await Future.wait([
        svc.fetchModelDetail(widget.modelId),
        svc.fetchReviews(widget.modelId),
      ]);

      if (!mounted) return;
      setState(() {
        _model = results[0] as MarketplaceModel;
        _reviews = results[1] as List<ModelReview>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _error != null
          ? _buildError()
          : _model != null
          ? _buildContent()
          : const SizedBox.shrink(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Failed to load model',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadData,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final model = _model!;
    return CustomScrollView(
      slivers: [
        // ─── App Bar ───────────────────────────────────
        SliverAppBar(
          backgroundColor: AppColors.background,
          pinned: true,
          expandedHeight: model.thumbnailUrl != null ? 220 : 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Consumer<AuthService>(
              builder: (context, auth, _) {
                if (!auth.isAuthenticated) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    model.isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: model.isFavorited
                        ? Colors.redAccent
                        : AppColors.textSecondary,
                  ),
                  onPressed: () async {
                    final svc = context.read<MarketplaceService>();
                    await svc.toggleFavorite(model.id);
                    setState(() {
                      _model = model.copyWith(isFavorited: !model.isFavorited);
                    });
                  },
                );
              },
            ),
          ],
          flexibleSpace: model.thumbnailUrl != null
              ? FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: model.thumbnailUrl!,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                )
              : null,
        ),
        // ─── Body ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + version
                Text(
                  model.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${model.version} · ${model.fileFormat.toUpperCase()} · ${model.fileSizeFormatted}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                // Publisher row
                _buildPublisherRow(model),
                const SizedBox(height: 16),
                // Stats row
                _buildStatsRow(model),
                const SizedBox(height: 20),
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  model.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Tags
                if (model.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: model.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // License + date
                _infoRow('License', model.licenseType),
                _infoRow('Published', timeago.format(model.createdAt)),
                _infoRow('Updated', timeago.format(model.updatedAt)),
                const SizedBox(height: 24),
                // ─── Download / Activate button ──────────
                _buildDownloadButton(model),
                const SizedBox(height: 30),
                // ─── Reviews section ─────────────────────
                _buildReviewsSection(model),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublisherRow(MarketplaceModel model) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.border,
          backgroundImage: model.publisherAvatarUrl != null
              ? CachedNetworkImageProvider(model.publisherAvatarUrl!)
              : null,
          child: model.publisherAvatarUrl == null
              ? const Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.textSecondary,
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          model.publisherName ?? 'Unknown',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(MarketplaceModel model) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statColumn(
            Icons.download_rounded,
            '${model.downloadCount}',
            'Downloads',
          ),
          Container(width: 1, height: 28, color: AppColors.border),
          _statColumn(
            Icons.star_rounded,
            model.avgRating.toStringAsFixed(1),
            '${model.reviewCount} reviews',
            iconColor: AppColors.warning,
          ),
          Container(width: 1, height: 28, color: AppColors.border),
          _statColumn(Icons.storage_rounded, model.fileSizeFormatted, 'Size'),
        ],
      ),
    );
  }

  Widget _statColumn(
    IconData icon,
    String value,
    String label, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppColors.accent),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Download button ─────────────────────────────────────

  Widget _buildDownloadButton(MarketplaceModel model) {
    return Consumer<DownloadManager>(
      builder: (context, dm, _) {
        final state = dm.getDownloadState(model.id);
        final isDownloaded = dm.isDownloaded(model.id);

        // Already downloaded → Activate button
        if (isDownloaded && state?.status != DownloadStatus.downloading) {
          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    dm.activateModel(model.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${model.name} activated!'),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Activate Model',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _confirmDelete(model),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
              ),
            ],
          );
        }

        // Downloading → progress bar
        if (state != null && state.isDownloading) {
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(state.progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => dm.cancelDownload(model.id),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Validating
        if (state?.status == DownloadStatus.validating) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Validating model...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Failed
        if (state?.isFailed == true) {
          return Column(
            children: [
              Text(
                state!.error ?? 'Download failed',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _downloadButton(model, dm, 'Retry Download'),
            ],
          );
        }

        // Default → Download
        return _downloadButton(model, dm, 'Download Model');
      },
    );
  }

  Widget _downloadButton(
    MarketplaceModel model,
    DownloadManager dm,
    String label,
  ) {
    return GestureDetector(
      onTap: () {
        dm.downloadModel(
          model,
          onWifiWarning: () => _showWifiWarning(model, dm),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWifiWarning(MarketplaceModel model, DownloadManager dm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Large File',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This model is ${model.fileSizeFormatted}. '
          'You are not on Wi-Fi. Continue anyway?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Force download regardless of connection
              dm.downloadModel(model);
            },
            child: const Text(
              'Download',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MarketplaceModel model) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Model',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove the downloaded file for ${model.name}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DownloadManager>().deleteDownloadedModel(model.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reviews section ──────────────────────────────────────

  Widget _buildReviewsSection(MarketplaceModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Reviews',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${model.reviewCount}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Write review form (if authenticated)
        Consumer<AuthService>(
          builder: (context, auth, _) {
            if (!auth.isAuthenticated) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Sign in to write a review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }

            return _buildReviewForm(model);
          },
        ),
        const SizedBox(height: 16),
        // Reviews list
        if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No reviews yet. Be the first!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          )
        else
          ..._reviews.map((review) => _buildReviewCard(review)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildReviewForm(MarketplaceModel model) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star rating
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = i + 1),
                child: Icon(
                  i < _selectedRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.warning,
                  size: 28,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Text field
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Write your review...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _isSubmitting ? null : () => _submitReview(model),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isSubmitting ? AppColors.border : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(MarketplaceModel model) async {
    if (_reviewController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final svc = context.read<MarketplaceService>();
      await svc.submitReview(
        model.id,
        _selectedRating,
        reviewText: _reviewController.text.trim(),
      );

      _reviewController.clear();
      _selectedRating = 5;

      // Reload reviews
      final reviews = await svc.fetchReviews(model.id);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildReviewCard(ModelReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.border,
                backgroundImage: review.avatarUrl != null
                    ? CachedNetworkImageProvider(review.avatarUrl!)
                    : null,
                child: review.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.username ?? 'Anonymous',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                timeago.format(review.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Stars
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: AppColors.warning,
                size: 16,
              );
            }),
          ),
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.reviewText!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
