import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// First-paint placeholder for create-event (shimmer rhythm matches profile/feed).
class CreateEventScreenSkeleton extends StatefulWidget {
  const CreateEventScreenSkeleton({super.key});

  @override
  State<CreateEventScreenSkeleton> createState() =>
      _CreateEventScreenSkeletonState();
}

class _CreateEventScreenSkeletonState extends State<CreateEventScreenSkeleton>
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
    return Semantics(
      label: context.l10n.createEventLoadingSemantic,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return AnimatedBuilder(
              animation: _shimmer,
              builder: (BuildContext context, Widget? child) {
                final double t = _shimmer.value;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _StepBarSkeleton(t: t),
                          const SizedBox(height: AppSpacing.sm),
                          _SiteCardSkeleton(t: t),
                          const SizedBox(height: AppSpacing.lg),
                          _CalendarSkeleton(t: t),
                          const SizedBox(height: AppSpacing.lg),
                          _TimeRowSkeleton(t: t),
                          const SizedBox(height: AppSpacing.lg),
                          _FieldSkeleton(t: t, widthFactor: 0.55),
                          const SizedBox(height: AppSpacing.md),
                          _FieldSkeleton(t: t, widthFactor: 1),
                          const SizedBox(height: AppSpacing.md),
                          _FieldSkeleton(t: t, widthFactor: 0.72),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StepBarSkeleton extends StatelessWidget {
  const _StepBarSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.sm),
      child: Row(
        children: <Widget>[
          _ShimmerBox(width: 88, height: 12, radius: 4, t: t),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ShimmerBox(
              width: double.infinity,
              height: 4,
              radius: 2,
              t: t,
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteCardSkeleton extends StatelessWidget {
  const _SiteCardSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ShimmerBox(width: 120, height: 14, radius: 6, t: t),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ShimmerBox(width: 44, height: 44, radius: 14, t: t),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ShimmerBox(
                      width: double.infinity,
                      height: 14,
                      radius: 6,
                      t: t,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ShimmerBox(
                      width: double.infinity,
                      height: 10,
                      radius: 5,
                      t: t,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ShimmerBox(width: 160, height: 14, radius: 6, t: t),
        const SizedBox(height: AppSpacing.md),
        _ShimmerBox(
          width: double.infinity,
          height: 200,
          radius: AppSpacing.radiusMd,
          t: t,
        ),
      ],
    );
  }
}

class _TimeRowSkeleton extends StatelessWidget {
  const _TimeRowSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ShimmerBox(
            width: double.infinity,
            height: 48,
            radius: AppSpacing.radius14,
            t: t,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ShimmerBox(
            width: double.infinity,
            height: 48,
            radius: AppSpacing.radius14,
            t: t,
          ),
        ),
      ],
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton({
    required this.t,
    required this.widthFactor,
  });

  final double t;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ShimmerBox(
              width: 96,
              height: 12,
              radius: 5,
              t: t,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ShimmerBox(
              width: constraints.maxWidth * widthFactor,
              height: 48,
              radius: AppSpacing.radius14,
              t: t,
            ),
          ],
        );
      },
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
      width: width.isFinite ? width : null,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
