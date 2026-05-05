import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_sub_screen_header.dart';

/// Shimmer layout matching [ProfilePointsHistoryScreen] while history loads.
class ProfilePointsHistorySkeleton extends StatefulWidget {
  const ProfilePointsHistorySkeleton({super.key});

  @override
  State<ProfilePointsHistorySkeleton> createState() =>
      _ProfilePointsHistorySkeletonState();
}

class _ProfilePointsHistorySkeletonState extends State<ProfilePointsHistorySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: ProfileSubScreenHeader(
            title: context.l10n.profilePointsHistoryTitle,
            subtitle: context.l10n.profilePointsHistorySubtitle,
            includeBottomSpacing: false,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: Semantics(
            label: context.l10n.profilePointsHistoryLoadingSemantic,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (BuildContext context, Widget? child) {
                  final double t = _shimmer.value;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: _PointsHistorySummarySkeleton(t: t),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            0,
                            AppSpacing.sm,
                          ),
                          child: _ShimmerBox(
                            width: 100,
                            height: 14,
                            radius: 7,
                            t: t,
                          ),
                        ),
                        SizedBox(
                          height: 112,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (_, _) =>
                                _MilestoneChipSkeleton(t: t),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: _ShimmerBox(
                            width: 88,
                            height: 14,
                            radius: 7,
                            t: t,
                          ),
                        ),
                        ...List<Widget>.generate(
                          5,
                          (int i) => Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              i == 0 ? 0 : AppSpacing.xs,
                              AppSpacing.lg,
                              AppSpacing.xs,
                            ),
                            child: _ActivityRowSkeleton(t: t),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointsHistorySummarySkeleton extends StatelessWidget {
  const _PointsHistorySummarySkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        children: <Widget>[
          _ShimmerBox(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            radius: AppSpacing.radius14,
            t: t,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ShimmerBox(width: 160, height: 16, radius: 8, t: t),
                const SizedBox(height: 8),
                _ShimmerBox(width: 120, height: 13, radius: 6, t: t),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneChipSkeleton extends StatelessWidget {
  const _MilestoneChipSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        color: AppColors.panelBackground,
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _ShimmerBox(width: 72, height: 14, radius: 7, t: t),
          _ShimmerBox(width: 130, height: 32, radius: 8, t: t),
          _ShimmerBox(width: 56, height: 12, radius: 6, t: t),
        ],
      ),
    );
  }
}

class _ActivityRowSkeleton extends StatelessWidget {
  const _ActivityRowSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: <Widget>[
            _ShimmerBox(width: 44, height: 44, radius: AppSpacing.radius14, t: t),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ShimmerBox(
                    width: double.infinity,
                    height: 15,
                    radius: 7,
                    t: t,
                  ),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: 64, height: 12, radius: 6, t: t),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ShimmerBox(width: 52, height: 18, radius: 8, t: t),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.t,
  });

  final double width;
  final double height;
  final double radius;
  final double t;

  @override
  Widget build(BuildContext context) {
    final double opacity =
        0.06 + 0.04 * (0.5 + 0.5 * (1 - (2 * t - 1).abs()));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
