import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_service.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'model_detail_screen.dart';
import 'publish_screen.dart';
import 'widgets/filter_chips.dart';
import 'widgets/model_card.dart';
import 'widgets/model_card_skeleton.dart';
import 'widgets/search_bar_widget.dart';

/// Main marketplace tab screen – browse, search, filter & infinite-scroll
/// through AI models.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial fetch if list is empty.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<MarketplaceService>();
      if (svc.models.isEmpty && !svc.isLoading) {
        svc.refresh();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 300) {
      final svc = context.read<MarketplaceService>();
      if (!svc.isLoading && svc.hasMore) {
        svc.loadMore();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Model Marketplace',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Auth button
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      if (auth.isAuthenticated) {
                        return GestureDetector(
                          onTap: () => _showPublishSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Publish',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login_rounded,
                                  size: 18, color: AppColors.accent),
                              SizedBox(width: 4),
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ─── Search ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MarketplaceSearchBar(
                controller: _searchController,
                onChanged: (q) =>
                    context.read<MarketplaceService>().updateSearch(q),
              ),
            ),
            const SizedBox(height: 12),
            // ─── Filters ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Consumer<MarketplaceService>(
                builder: (context, svc, _) {
                  return FilterChips(
                    currentSort: svc.sort,
                    selectedTags: svc.selectedTags,
                    onSortChanged: svc.updateSort,
                    onTagToggled: svc.toggleTag,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // ─── Model list ──────────────────────────────
            Expanded(
              child: Consumer<MarketplaceService>(
                builder: (context, svc, _) {
                  // Error state
                  if (svc.error != null && svc.models.isEmpty) {
                    return _buildError(svc);
                  }

                  // Loading initial
                  if (svc.isLoading && svc.models.isEmpty) {
                    return _buildSkeletons();
                  }

                  // Empty state
                  if (svc.models.isEmpty) {
                    return _buildEmpty();
                  }

                  // Model list
                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: svc.refresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          svc.models.length + (svc.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= svc.models.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          );
                        }

                        final model = svc.models[index];
                        return ModelCard(
                          model: model,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ModelDetailScreen(modelId: model.id),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty / Error / Skeleton helpers ──────────────────────

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, __) => const ModelCardSkeleton(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'No models found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MarketplaceService svc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              svc.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: svc.refresh,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublishSheet(BuildContext context) {
    final svc = context.read<MarketplaceService>();
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const PublishScreen()),
    ).then((published) {
      if (published == true) {
        svc.refresh();
      }
    });
  }
}
