import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/presentation/widgets/event_card_skeleton.dart';
import 'package:flutter/material.dart';

/// Full-feed loading placeholder for [EventsFeedScreen]: title, search, chips, then
/// list/calendar body. Inline in the parent [CustomScrollView] (no nested scroll, no
/// fixed chrome over the skeleton).
class EventsFeedSkeleton extends StatefulWidget {
  const EventsFeedSkeleton({super.key, this.calendarView = false});

  final bool calendarView;

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
    return Semantics(
      label: context.l10n.eventsFeedLoadingSemantic,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (BuildContext context, Widget? child) {
            final double t = _shimmer.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _EventsFeedHeaderSkeleton(t: t),
                if (widget.calendarView)
                  _EventsCalendarFeedSkeleton(t: t)
                else
                  _EventsListFeedSkeleton(t: t),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Title, search/tools, and filter chips — mirrors loaded feed chrome.
class _EventsFeedHeaderSkeleton extends StatelessWidget {
  const _EventsFeedHeaderSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    const double control = AppSpacing.eventsFeedToolbarControlSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SkeletonShimmerBox(
                  width: double.infinity,
                  height: 28,
                  radius: AppSpacing.radiusSm,
                  t: t,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SkeletonShimmerBox(
                width: control,
                height: control,
                radius: AppSpacing.radiusMd,
                t: t,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SkeletonShimmerBox(
                  width: double.infinity,
                  height: control,
                  radius: AppSpacing.radiusMd,
                  t: t,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SkeletonShimmerBox(
                width: control,
                height: control,
                radius: AppSpacing.radiusMd,
                t: t,
              ),
              const SizedBox(width: AppSpacing.xs),
              SkeletonShimmerBox(
                width: control,
                height: control,
                radius: AppSpacing.radiusMd,
                t: t,
              ),
              const SizedBox(width: AppSpacing.xxs),
              SkeletonShimmerBox(
                width: control,
                height: control,
                radius: AppSpacing.radiusMd,
                t: t,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final bool selected = index == 0;
                return SkeletonShimmerBox(
                  width: index == 4 ? 72 : 88,
                  height: 36,
                  radius: AppSpacing.radiusPill,
                  t: t,
                  baseTint: selected
                      ? AppColors.feedPillSelectedFill
                      : AppColors.divider.withValues(alpha: 0.55),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Section title shim — same padding as [SectionHeader] in events_sliver_list.dart.
class _EventsFeedSectionTitleSkeleton extends StatelessWidget {
  const _EventsFeedSectionTitleSkeleton({
    required this.t,
    required this.barWidth,
  });

  final double t;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SkeletonShimmerBox(
        width: barWidth,
        height: 12,
        radius: AppSpacing.radiusSm,
        t: t,
      ),
    );
  }
}

class _EventsListFeedSkeleton extends StatelessWidget {
  const _EventsListFeedSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _HeroEventSkeleton(t: t),
        ),
        _EventsFeedSectionTitleSkeleton(t: t, barWidth: 140),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              EventCardSkeleton(t: t, layoutSeed: 0, showLiveAccentStrip: true),
              const SizedBox(height: AppSpacing.sm),
              EventCardSkeleton(t: t, layoutSeed: 1, showStatusChipRow: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _EventsFeedSectionTitleSkeleton(t: t, barWidth: 120),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              EventCardSkeleton(t: t, layoutSeed: 2),
              const SizedBox(height: AppSpacing.sm),
              EventCardSkeleton(t: t, layoutSeed: 3),
              const SizedBox(height: AppSpacing.sm),
              EventCardSkeleton(t: t, layoutSeed: 4, showCheckedInRow: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _EventsFeedSectionTitleSkeleton(t: t, barWidth: 200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              EventCardSkeleton(t: t, layoutSeed: 5),
              const SizedBox(height: AppSpacing.sm),
              EventCardSkeleton(t: t, layoutSeed: 6),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mirrors [EventsCalendarView] chrome: month row, weekdays, 6×7 grid, agenda strip.
class _EventsCalendarFeedSkeleton extends StatelessWidget {
  const _EventsCalendarFeedSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _EventsSkeletonStaticPill(
                width: 40,
                height: 40,
                radius: AppSpacing.radiusMd,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
              ),
              Expanded(
                child: Center(
                  child: SkeletonShimmerBox(
                    width: 160,
                    height: 18,
                    radius: 9,
                    t: t,
                  ),
                ),
              ),
              _EventsSkeletonStaticPill(
                width: 40,
                height: 40,
                radius: AppSpacing.radiusMd,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List<Widget>.generate(7, (int i) {
              return Expanded(
                child: Center(
                  child: SkeletonShimmerBox(
                    width: 18 + (i % 3) * 2.0,
                    height: 10,
                    radius: 5,
                    t: t,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 1,
            maxScaleFactor: 1.5,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (BuildContext context, int index) {
                return SkeletonShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                  radius: 999,
                  t: t,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SkeletonShimmerBox(width: 200, height: 14, radius: 7, t: t),
          const SizedBox(height: AppSpacing.sm),
          _CalendarAgendaRowSkeleton(t: t),
          const SizedBox(height: AppSpacing.sm),
          _CalendarAgendaRowSkeleton(t: t, wideTitle: true),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _CalendarAgendaRowSkeleton extends StatelessWidget {
  const _CalendarAgendaRowSkeleton({required this.t, this.wideTitle = false});

  final double t;
  final bool wideTitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: <Widget>[
          SkeletonShimmerBox(
            width: 40,
            height: 40,
            radius: AppSpacing.radius10,
            t: t,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonShimmerBox(
                  width: wideTitle ? double.infinity : 180,
                  height: 14,
                  radius: 7,
                  t: t,
                ),
                const SizedBox(height: 6),
                SkeletonShimmerBox(width: 96, height: 11, radius: 5, t: t),
              ],
            ),
          ),
          SkeletonShimmerBox(width: 16, height: 16, radius: 8, t: t),
        ],
      ),
    );
  }
}

class _EventsSkeletonStaticPill extends StatelessWidget {
  const _EventsSkeletonStaticPill({
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

/// Same footprint as [HeroEventCard]: [AppSpacing.eventsHeroCardMediaHeight], overlays,
/// top-leading countdown pill, top-trailing “Up next” badge, title + meta.
class _HeroEventSkeleton extends StatelessWidget {
  const _HeroEventSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BorderRadius cardRadius = BorderRadius.circular(
      AppSpacing.radiusCard,
    );
    final double iconBox = (AppSpacing.iconSm * 0.75).roundToDouble();
    // Outer shell matches [HeroEventCard]: decoration + shadow, inner [ClipRRect] only.
    return Container(
      decoration: AppCardChrome.discoveryHeroOuter(colorScheme),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: SizedBox(
          height: AppSpacing.eventsHeroCardMediaHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: SkeletonShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                  radius: 0,
                  t: t,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: cardRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.transparent,
                        colorScheme.scrim.withValues(alpha: 0.62),
                      ],
                      stops: const <double>[0.32, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.scrim.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.radiusSm,
                      vertical: AppSpacing.xxs,
                    ),
                    child: SkeletonShimmerBox(
                      width: 96,
                      height: 12,
                      radius: AppSpacing.radiusSm,
                      t: t,
                      baseTint: AppColors.textOnDark,
                      tintPulseBoost: 0.08,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppSpacing.radius10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.radius10,
                      vertical: AppSpacing.xxs,
                    ),
                    child: SkeletonShimmerBox(
                      width: 56,
                      height: 11,
                      radius: AppSpacing.radiusSm,
                      t: t,
                      baseTint: AppColors.textOnDark,
                      tintPulseBoost: 0.14,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SkeletonShimmerBox(
                      width: double.infinity,
                      height: 18,
                      radius: AppSpacing.radiusSm,
                      t: t,
                      baseTint: AppColors.white,
                      tintPulseBoost: 0.12,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        SkeletonShimmerBox(
                          width: iconBox,
                          height: iconBox,
                          radius: 3,
                          t: t,
                          baseTint: AppColors.white,
                          tintPulseBoost: 0.12,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: SkeletonShimmerBox(
                            width: double.infinity,
                            height: 14,
                            radius: 6,
                            t: t,
                            baseTint: AppColors.white,
                            tintPulseBoost: 0.12,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.radiusSm),
                        SkeletonShimmerBox(
                          width: 64,
                          height: 14,
                          radius: 6,
                          t: t,
                          baseTint: AppColors.white,
                          tintPulseBoost: 0.12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
