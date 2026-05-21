import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/atoms/skeleton_shimmer_box.dart';
import 'package:flutter/material.dart';

class SiteHistorySkeleton extends StatefulWidget {
  const SiteHistorySkeleton({super.key});

  @override
  State<SiteHistorySkeleton> createState() => _SiteHistorySkeletonState();
}

class _SiteHistorySkeletonState extends State<SiteHistorySkeleton>
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
    final double t = _shimmer.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        SkeletonShimmerBox(width: 96, height: 12, radius: AppSpacing.radiusSm, t: t),
        const SizedBox(height: AppSpacing.sm),
        SkeletonShimmerBox(
          width: double.infinity,
          height: 56,
          radius: AppSpacing.radius18,
          t: t,
        ),
        const SizedBox(height: AppSpacing.xs),
        SkeletonShimmerBox(width: 72, height: 10, radius: AppSpacing.radiusSm, t: t),
        const SizedBox(height: AppSpacing.lg),
        SkeletonShimmerBox(width: 80, height: 12, radius: AppSpacing.radiusSm, t: t),
        const SizedBox(height: AppSpacing.sm),
        SkeletonShimmerBox(
          width: double.infinity,
          height: 120,
          radius: AppSpacing.radius18,
          t: t,
        ),
      ],
    );
  }
}
