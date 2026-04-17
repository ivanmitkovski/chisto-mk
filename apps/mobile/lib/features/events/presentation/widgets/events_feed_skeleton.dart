import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_card_skeleton.dart';

/// Loading placeholder for the events feed (hero + stacked cards).
class EventsFeedSkeleton extends StatefulWidget {
  const EventsFeedSkeleton({super.key});

  @override
  State<EventsFeedSkeleton> createState() => _EventsFeedSkeletonState();
}

class _EventsFeedSkeletonState extends State<EventsFeedSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: AppMotion.slow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.syncRepeatingShimmer(_shimmer, context);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (BuildContext context, Widget? child) {
        final double t = _shimmer.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HeroBlock(t: t),
              const SizedBox(height: AppSpacing.lg),
              const EventCardSkeleton(),
              const SizedBox(height: AppSpacing.sm),
              const EventCardSkeleton(),
              const SizedBox(height: AppSpacing.sm),
              const EventCardSkeleton(),
              const SizedBox(height: AppSpacing.sm),
              const EventCardSkeleton(),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment(-1 + t * 2, 0),
          end: Alignment(1 + t * 2, 0),
          colors: <Color>[
            AppColors.panelBackground,
            AppColors.panelBackground.withValues(alpha: 0.65),
            AppColors.panelBackground,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
