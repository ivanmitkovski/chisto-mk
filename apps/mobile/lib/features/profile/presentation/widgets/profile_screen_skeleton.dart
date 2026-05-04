import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/no_overscroll_overlay_scroll_behavior.dart';

/// Full-profile loading placeholder: gradient header + level, credits, weekly cards.
class ProfileScreenSkeleton extends StatefulWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  State<ProfileScreenSkeleton> createState() => _ProfileScreenSkeletonState();
}

class _ProfileScreenSkeletonState extends State<ProfileScreenSkeleton>
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
    return Semantics(
      label: context.l10n.profileLoadingSemantic,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _SkeletonHeaderStrip(),
            Expanded(
              child: ClipRect(
                clipper: const _ProfileSkeletonScrollClipper(
                  bottomExtension: AppSpacing.xxl + AppSpacing.xl,
                ),
                child: ScrollConfiguration(
                  behavior: const NoOverscrollOverlayScrollBehavior(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl + AppSpacing.lg,
                    ),
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (BuildContext context, Widget? child) {
                        final double t = _shimmer.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _LevelCardSkeleton(t: t),
                            const SizedBox(height: AppSpacing.md),
                            _ReportCreditsCardSkeleton(t: t),
                            const SizedBox(height: AppSpacing.md),
                            _WeeklyRankCardSkeleton(t: t),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Credits row shimmer while reporting capacity is loading (initial load only).
class ProfileReportCreditsSkeleton extends StatefulWidget {
  const ProfileReportCreditsSkeleton({super.key});

  @override
  State<ProfileReportCreditsSkeleton> createState() =>
      _ProfileReportCreditsSkeletonState();
}

class _ProfileReportCreditsSkeletonState extends State<ProfileReportCreditsSkeleton>
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
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (BuildContext context, Widget? child) {
          return _ReportCreditsCardSkeleton(t: _shimmer.value);
        },
      ),
    );
  }
}

class _ProfileSkeletonScrollClipper extends CustomClipper<Rect> {
  const _ProfileSkeletonScrollClipper({required this.bottomExtension});

  final double bottomExtension;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height + bottomExtension,
      );

  @override
  bool shouldReclip(covariant _ProfileSkeletonScrollClipper oldClipper) =>
      oldClipper.bottomExtension != bottomExtension;
}

class _SkeletonHeaderStrip extends StatelessWidget {
  const _SkeletonHeaderStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _StaticPill(
                  width: 40,
                  height: 40,
                  radius: 12,
                  color: AppColors.white.withValues(alpha: 0.2),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _StaticPill(
                  width: AppSpacing.avatarLg,
                  height: AppSpacing.avatarLg,
                  radius: AppSpacing.avatarLg / 2,
                  color: AppColors.white.withValues(alpha: 0.18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _StaticPill(
                        width: 160,
                        height: 18,
                        radius: 9,
                        color: AppColors.white.withValues(alpha: 0.22),
                      ),
                      const SizedBox(height: AppSpacing.xxs + 2),
                      _StaticPill(
                        width: 120,
                        height: 14,
                        radius: 7,
                        color: AppColors.white.withValues(alpha: 0.16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCardSkeleton extends StatelessWidget {
  const _LevelCardSkeleton({required this.t});

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
                    _ShimmerBox(width: 140, height: 16, radius: 8, t: t),
                    const SizedBox(height: 6),
                    _ShimmerBox(width: double.infinity, height: 12, radius: 6, t: t),
                  ],
                ),
              ),
              _ShimmerBox(width: 22, height: 22, radius: 11, t: t),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ShimmerBox(
            width: double.infinity,
            height: AppSpacing.radius18,
            radius: AppSpacing.radiusCircle,
            t: t,
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: _ShimmerBox(width: double.infinity, height: 12, radius: 6, t: t),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ShimmerBox(width: double.infinity, height: 11, radius: 5, t: t),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCreditsCardSkeleton extends StatelessWidget {
  const _ReportCreditsCardSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: _ShimmerBox(width: 140, height: 16, radius: 8, t: t),
          ),
          _ShimmerBox(width: 44, height: 28, radius: 14, t: t),
        ],
      ),
    );
  }
}

class _WeeklyRankCardSkeleton extends StatelessWidget {
  const _WeeklyRankCardSkeleton({required this.t});

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
                _ShimmerBox(width: 120, height: 16, radius: 8, t: t),
                const SizedBox(height: 4),
                _ShimmerBox(width: 180, height: 12, radius: 6, t: t),
              ],
            ),
          ),
          _ShimmerBox(width: 22, height: 22, radius: 11, t: t),
        ],
      ),
    );
  }
}

class _StaticPill extends StatelessWidget {
  const _StaticPill({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
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
