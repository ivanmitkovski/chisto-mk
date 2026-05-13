import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_card_chrome.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/skeleton_shimmer_box.dart';

/// Placeholder row for a stacked [EcoEventCard] while the parent drives shimmer [t].
///
/// Shell matches [EcoEventCard] (surface container, card radius, outline, shadow pair).
/// [layoutSeed] tweaks line widths so stacked skeletons do not look identical.
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({
    super.key,
    required this.t,
    this.layoutSeed = 0,
    this.showLiveAccentStrip = false,
    this.showStatusChipRow = false,
    this.showCheckedInRow = false,
  });

  final double t;
  final int layoutSeed;
  final bool showLiveAccentStrip;
  final bool showStatusChipRow;
  final bool showCheckedInRow;

  static const double _kMetaIconSize = 14;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BorderRadius cardRadius =
        BorderRadius.circular(AppSpacing.radiusCard);
    final int s = layoutSeed % 3;
    final double titleLine2Width = s == 0 ? 0.72 : (s == 1 ? 0.55 : 0.88);
    final double locationLineWidth = s == 0 ? 0.62 : (s == 1 ? 0.78 : 0.5);

    return Container(
      decoration: AppCardChrome.discoveryListCard(colorScheme),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            if (showLiveAccentStrip)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ColoredBox(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  child: const SizedBox(width: AppSpacing.eventsLiveAccentWidth),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonShimmerBox(
                    width: AppSpacing.eventsCardThumbnailSize,
                    height: AppSpacing.eventsCardThumbnailSize,
                    radius: AppSpacing.radius14,
                    t: t,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SkeletonShimmerBox(
                                    width: 92,
                                    height: 10,
                                    radius: 5,
                                    t: t,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  SkeletonShimmerBox(
                                    width: double.infinity,
                                    height: 14,
                                    radius: 7,
                                    t: t,
                                  ),
                                  const SizedBox(height: 5),
                                  LayoutBuilder(
                                    builder:
                                        (BuildContext context, BoxConstraints c) {
                                      return SkeletonShimmerBox(
                                        width: c.maxWidth * titleLine2Width,
                                        height: 14,
                                        radius: 7,
                                        t: t,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            SkeletonShimmerBox(
                              width: AppSpacing.iconSm,
                              height: AppSpacing.iconSm,
                              radius: AppSpacing.radiusSm,
                              t: t,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (showStatusChipRow)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SkeletonShimmerBox(
                                width: 56,
                                height: 20,
                                radius: AppSpacing.radius10,
                                t: t,
                                baseTint: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: SkeletonShimmerBox(
                                  width: double.infinity,
                                  height: 12,
                                  radius: 6,
                                  t: t,
                                ),
                              ),
                            ],
                          )
                        else
                          SkeletonShimmerBox(
                            width: double.infinity,
                            height: 12,
                            radius: 6,
                            t: t,
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              CupertinoIcons.location_solid,
                              size: _kMetaIconSize,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.35),
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: LayoutBuilder(
                                builder:
                                    (BuildContext context, BoxConstraints c) {
                                  return SkeletonShimmerBox(
                                    width: c.maxWidth * locationLineWidth,
                                    height: 11,
                                    radius: 5,
                                    t: t,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        if (showCheckedInRow) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: <Widget>[
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: _kMetaIconSize,
                                color: colorScheme.primary
                                    .withValues(alpha: 0.35),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              SkeletonShimmerBox(
                                width: 120,
                                height: 12,
                                radius: 6,
                                t: t,
                                baseTint: colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
