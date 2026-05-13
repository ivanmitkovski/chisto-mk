import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_card_chrome.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_card_skeleton.dart';
import 'package:chisto_mobile/shared/widgets/no_overscroll_overlay_scroll_behavior.dart';
import 'package:chisto_mobile/shared/widgets/skeleton_shimmer_box.dart';

/// Loading placeholder for the events feed body: mirrors loaded order — [HeroEventCard],
/// then sectioned list rows (or calendar grid when [calendarView] is true).
/// One shimmer pass; scroll shell matches [ProfileScreenSkeleton].
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
      label: context.l10n.eventsFeedLoadingSemantic,
      child: ExcludeSemantics(
        child: ClipRect(
          clipper: const _EventsFeedSkeletonScrollClipper(
            bottomExtension: AppSpacing.xxl + AppSpacing.xl,
          ),
          child: ScrollConfiguration(
            behavior: const NoOverscrollOverlayScrollBehavior(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              clipBehavior: Clip.none,
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpacing.md,
                    0,
                    AppSpacing.xl + AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (BuildContext context, Widget? child) {
                        final double t = _shimmer.value;
                        return widget.calendarView
                            ? _EventsCalendarFeedSkeleton(t: t)
                            : _EventsListFeedSkeleton(t: t);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsFeedSkeletonScrollClipper extends CustomClipper<Rect> {
  const _EventsFeedSkeletonScrollClipper({required this.bottomExtension});

  final double bottomExtension;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height + bottomExtension,
      );

  @override
  bool shouldReclip(covariant _EventsFeedSkeletonScrollClipper oldClipper) =>
      oldClipper.bottomExtension != bottomExtension;
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
              EventCardSkeleton(
                t: t,
                layoutSeed: 0,
                showLiveAccentStrip: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              EventCardSkeleton(
                t: t,
                layoutSeed: 1,
                showStatusChipRow: true,
              ),
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
              EventCardSkeleton(
                t: t,
                layoutSeed: 4,
                showCheckedInRow: true,
              ),
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
        const SizedBox(height: AppSpacing.lg),
        _EventsFeedSectionTitleSkeleton(t: t, barWidth: 168),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              EventCardSkeleton(t: t, layoutSeed: 7),
              const SizedBox(height: AppSpacing.sm),
              EventCardSkeleton(
                t: t,
                layoutSeed: 8,
                showCheckedInRow: true,
              ),
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
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
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
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
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
          SkeletonShimmerBox(
            width: 200,
            height: 14,
            radius: 7,
            t: t,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CalendarAgendaRowSkeleton(t: t),
          const SizedBox(height: AppSpacing.sm),
          _CalendarAgendaRowSkeleton(t: t, wideTitle: true),
        ],
      ),
    );
  }
}

class _CalendarAgendaRowSkeleton extends StatelessWidget {
  const _CalendarAgendaRowSkeleton({
    required this.t,
    this.wideTitle = false,
  });

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
                SkeletonShimmerBox(
                  width: 96,
                  height: 11,
                  radius: 5,
                  t: t,
                ),
              ],
            ),
          ),
          SkeletonShimmerBox(
            width: 16,
            height: 16,
            radius: 8,
            t: t,
          ),
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
    final double iconBox = (AppSpacing.iconSm * 0.75).roundToDouble();
    return Container(
      height: AppSpacing.eventsHeroCardMediaHeight,
      decoration: AppCardChrome.discoveryHeroOuter(colorScheme),
      clipBehavior: Clip.antiAlias,
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    colorScheme.scrim.withValues(alpha: 0.62),
                  ],
                  stops: const <double>[0.32, 1.0],
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
    );
  }
}
