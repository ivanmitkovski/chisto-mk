import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_layout.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';

/// Placeholder while a single event is fetched from the API.
///
/// Mirrors the real layout depth: hero → status pill → title → facts cards
/// (schedule + location + meta strip) → gear chips → description lines (×5) → participants row
/// — roughly 10 distinct skeleton items.
///
/// When `MediaQuery.disableAnimationsOf` is true the pulse is skipped and a
/// static low-opacity band is rendered instead.
class EventDetailSkeleton extends StatefulWidget {
  const EventDetailSkeleton({super.key});

  @override
  State<EventDetailSkeleton> createState() => _EventDetailSkeletonState();
}

class _EventDetailSkeletonState extends State<EventDetailSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _pulse?.dispose();
      _pulse = null;
    } else {
      _pulse ??= AnimationController(vsync: this, duration: AppMotion.slow)
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pulse == null) {
      return _buildBody(context, AppColors.textMuted.withValues(alpha: 0.08));
    }
    return AnimatedBuilder(
      animation: _pulse!,
      builder: (BuildContext context, Widget? child) {
        final double t = _pulse!.value;
        final double opacity = 0.06 + 0.04 * (0.5 + 0.5 * (1 - (2 * t - 1).abs()));
        return _buildBody(context, AppColors.textMuted.withValues(alpha: opacity));
      },
    );
  }

  Widget _buildBody(BuildContext context, Color band) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: <Widget>[
        // ── Hero band ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(height: kEventDetailHeroExpandedHeight, color: band),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            kEventDetailBodyHorizontalGutter,
            kEventDetailBodyHorizontalGutter,
            kEventDetailBodyHorizontalGutter,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              // ── Status pill ─────────────────────────────────────────────
              _Bar(band: band, height: 22, width: 80, radius: AppSpacing.radiusPill),
              const SizedBox(height: AppSpacing.sm),

              // ── Title ───────────────────────────────────────────────────
              _Bar(band: band, height: 28, widthFactor: 0.72),
              const SizedBox(height: AppSpacing.xs),
              _Bar(band: band, height: 28, widthFactor: 0.48),
              const SizedBox(height: AppSpacing.lg),

              // ── Facts: schedule + location + meta chips ───────────────────
              _FactsSectionSkeleton(band: band),
              const SizedBox(height: AppSpacing.lg),

              // ── Gear header + chips ──────────────────────────────────────
              _Bar(band: band, height: 16, width: 120),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  _Bar(band: band, height: 32, width: 90, radius: AppSpacing.radiusMd),
                  const SizedBox(width: AppSpacing.xs),
                  _Bar(band: band, height: 32, width: 110, radius: AppSpacing.radiusMd),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Description header + 5 lines ────────────────────────────
              _Bar(band: band, height: 16, width: 140),
              const SizedBox(height: AppSpacing.sm),
              _Bar(band: band, height: 13, widthFactor: 1.0),
              const SizedBox(height: AppSpacing.xs),
              _Bar(band: band, height: 13, widthFactor: 1.0),
              const SizedBox(height: AppSpacing.xs),
              _Bar(band: band, height: 13, widthFactor: 1.0),
              const SizedBox(height: AppSpacing.xs),
              _Bar(band: band, height: 13, widthFactor: 0.9),
              const SizedBox(height: AppSpacing.xs),
              _Bar(band: band, height: 13, widthFactor: 0.65),
              const SizedBox(height: AppSpacing.lg),

              // ── Participants row ─────────────────────────────────────────
              _ParticipantsSkeleton(band: band),
            ]),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

class _Bar extends StatelessWidget {
  const _Bar({
    required this.band,
    required this.height,
    this.width,
    this.widthFactor,
    this.radius = 6,
  }) : assert(
          width != null || widthFactor != null,
          'Provide width or widthFactor',
        );

  final Color band;
  final double height;
  final double? width;
  final double? widthFactor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: band,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return widthFactor != null
        ? FractionallySizedBox(widthFactor: widthFactor, child: child)
        : child;
  }
}

/// Placeholder blocks mirroring [EventDetailFactsSection] (soft cards + chip strip).
class _FactsSectionSkeleton extends StatelessWidget {
  const _FactsSectionSkeleton({required this.band});

  final Color band;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DetailModuleSkeleton(
          band: band,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Bar(band: band, height: 18, widthFactor: 0.45),
              const SizedBox(height: AppSpacing.sm),
              _Bar(band: band, height: 14, widthFactor: 0.62),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailModuleSkeleton(
          band: band,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: band,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Bar(band: band, height: 11, width: 72),
                    const SizedBox(height: AppSpacing.xs),
                    _Bar(band: band, height: 14, widthFactor: 0.92),
                    const SizedBox(height: 4),
                    _Bar(band: band, height: 14, widthFactor: 0.78),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailModuleSkeleton(
          band: band,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _Bar(band: band, height: 32, width: 96, radius: AppSpacing.radiusMd),
              _Bar(band: band, height: 32, width: 120, radius: AppSpacing.radiusMd),
              _Bar(band: band, height: 32, width: 88, radius: AppSpacing.radiusMd),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailModuleSkeleton extends StatelessWidget {
  const _DetailModuleSkeleton({
    required this.band,
    required this.child,
  });

  final Color band;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: EventDetailSurfaceDecoration.detailModule(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

/// Mimics the participants card: avatar circles + two lines of text.
class _ParticipantsSkeleton extends StatelessWidget {
  const _ParticipantsSkeleton({required this.band});

  final Color band;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: EventDetailSurfaceDecoration.detailModule(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            // Avatar stack placeholder
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: band,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.detailSurfaceModule,
                      width: 2,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Bar(band: band, height: 13, widthFactor: 0.6),
                  const SizedBox(height: 4),
                  _Bar(band: band, height: 11, widthFactor: 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
