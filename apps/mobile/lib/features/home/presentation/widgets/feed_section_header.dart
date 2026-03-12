import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';

class FeedSectionHeader extends StatelessWidget {
  const FeedSectionHeader({
    super.key,
    required this.activeFilter,
    required this.sitesCount,
    required this.onFilterTap,
  });

  final FeedFilter activeFilter;
  final int sitesCount;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              'Pollution sites',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Semantics(
            button: true,
            label: 'Filter feed',
            value: activeFilter.label,
            child: GestureDetector(
              onTap: onFilterTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.emphasized,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: activeFilter == FeedFilter.all
                      ? AppColors.panelBackground
                      : AppColors.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeFilter == FeedFilter.all
                        ? AppColors.divider
                        : AppColors.primaryDark.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: activeFilter == FeedFilter.all
                      ? null
                      : <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      activeFilter.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: activeFilter == FeedFilter.all
                                ? AppColors.textSecondary
                                : AppColors.primaryDark,
                            fontSize: 13,
                            letterSpacing: -0.1,
                          ),
                    ),
                    if (activeFilter != FeedFilter.all && sitesCount > 0)
                      ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$sitesCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: activeFilter == FeedFilter.all
                          ? AppColors.textMuted
                          : AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
