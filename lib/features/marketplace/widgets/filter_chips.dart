import 'package:flutter/material.dart';

import '../../../core/services/marketplace_service.dart';
import '../../../core/theme/app_colors.dart';

/// Sort and filter chips row for the marketplace.
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.currentSort,
    required this.selectedTags,
    required this.onSortChanged,
    required this.onTagToggled,
  });

  final MarketplaceSort currentSort;
  final Set<String> selectedTags;
  final ValueChanged<MarketplaceSort> onSortChanged;
  final ValueChanged<String> onTagToggled;

  static const List<String> _popularTags = [
    'detection',
    'segmentation',
    'classification',
    'pose',
    'obb',
    'yolo',
    'custom',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort chips
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: MarketplaceSort.values.map((sort) {
              final isSelected = sort == currentSort;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSortChanged(sort),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _sortLabel(sort),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Tag chips
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _popularTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onTagToggled(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _sortLabel(MarketplaceSort sort) {
    switch (sort) {
      case MarketplaceSort.newest:
        return 'Newest';
      case MarketplaceSort.mostDownloaded:
        return 'Most Downloaded';
      case MarketplaceSort.highestRated:
        return 'Highest Rated';
    }
  }
}
