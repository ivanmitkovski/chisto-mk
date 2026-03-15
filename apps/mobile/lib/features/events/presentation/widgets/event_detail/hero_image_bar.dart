import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

class HeroImageBar extends StatelessWidget {
  const HeroImageBar({
    super.key,
    required this.event,
    required this.onShare,
  });

  final EcoEvent event;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.panelBackground,
      leading: const Padding(
        padding: EdgeInsets.only(left: AppSpacing.sm),
        child: Center(child: AppBackButton()),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.appBackground.withValues(alpha: 0.85),
            child: IconButton(
              iconSize: 18,
              tooltip: 'Share event',
              onPressed: onShare,
              icon: const Icon(
                CupertinoIcons.share,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double expandRatio = ((constraints.maxHeight - kToolbarHeight) /
                  (260 - kToolbarHeight))
              .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Hero(
                  tag: 'event-thumb-${event.id}',
                  child: Transform.scale(
                    scale: 1.0 + (1.0 - expandRatio) * 0.05,
                    child: Image.asset(
                      event.siteImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                          Container(color: AppColors.inputFill),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.black.withValues(alpha: 0.1),
                        AppColors.black.withValues(alpha: 0.35 + (1 - expandRatio) * 0.2),
                      ],
                    ),
                  ),
                ),
                if (event.status == EcoEventStatus.upcoming)
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Opacity(
                      opacity: expandRatio,
                      child: CountdownBadge(event: event),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CountdownBadge extends StatelessWidget {
  const CountdownBadge({super.key, required this.event});
  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final Duration diff = event.startDateTime.difference(DateTime.now());
    if (diff.isNegative) return const SizedBox.shrink();

    final String label;
    if (diff.inDays > 0) {
      label = 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      label = 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      label = 'Starts in ${diff.inMinutes}m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radius10),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(CupertinoIcons.clock, size: 14, color: AppColors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
