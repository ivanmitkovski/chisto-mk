import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

/// Shimmer layout matching [WeeklyRankingsScreen] while rankings load.
class WeeklyRankingsSkeleton extends StatefulWidget {
  const WeeklyRankingsSkeleton({super.key});

  @override
  State<WeeklyRankingsSkeleton> createState() => _WeeklyRankingsSkeletonState();
}

class _WeeklyRankingsSkeletonState extends State<WeeklyRankingsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppBackButton(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.profileWeeklyRankingsTitle,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.profileWeeklyRankingsSubtitle,
                style: AppTypography.cardSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedBuilder(
                animation: _shimmer,
                builder: (BuildContext context, Widget? child) {
                  return _ShimmerBox(
                    width: 200,
                    height: 15,
                    radius: 7,
                    t: _shimmer.value,
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            context.l10n.profileWeeklyRankingsTopSupporters,
            style: AppTypography.cardSubtitle.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.05,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Semantics(
            label: context.l10n.profileWeeklyRankingsLoadingSemantic,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (BuildContext context, Widget? child) {
                  final double t = _shimmer.value;
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: 10,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (_, _) => _RankingRowSkeleton(t: t),
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

class _RankingRowSkeleton extends StatelessWidget {
  const _RankingRowSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: AppSpacing.xl,
            child: Center(
              child: _ShimmerBox(
                width: 18,
                height: 16,
                radius: 6,
                t: t,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ShimmerBox(
            width: AppSpacing.radius18 * 2,
            height: AppSpacing.radius18 * 2,
            radius: AppSpacing.radius18,
            t: t,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ShimmerBox(
              width: double.infinity,
              height: 16,
              radius: 8,
              t: t,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ShimmerBox(width: 28, height: 16, radius: 6, t: t),
        ],
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
