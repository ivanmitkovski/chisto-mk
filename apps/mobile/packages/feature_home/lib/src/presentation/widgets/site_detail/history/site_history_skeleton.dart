import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_grouped_panel.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_node.dart';
import 'package:flutter/material.dart';

/// Shimmer layout matching [SiteHistoryTab] while the first history page loads.
class SiteHistorySkeleton extends StatefulWidget {
  const SiteHistorySkeleton({super.key});

  static const double _statusHeaderBlockHeight = 136;
  static const double _timelineRowHeight = 72;

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

  int _rowCountForHeight(double viewportHeight) {
    const double verticalPadding =
        AppSpacing.md + AppSpacing.xxl + AppSpacing.lg;
    final double remaining =
        viewportHeight -
        verticalPadding -
        SiteHistorySkeleton._statusHeaderBlockHeight;
    if (remaining <= SiteHistorySkeleton._timelineRowHeight * 2) {
      return 4;
    }
    return (remaining / SiteHistorySkeleton._timelineRowHeight).ceil().clamp(
      4,
      8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.siteHistoryLoadingSemantic,
      liveRegion: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int rowCount = _rowCountForHeight(constraints.maxHeight);
            return AnimatedBuilder(
              animation: _shimmer,
              builder: (BuildContext context, Widget? child) {
                final double t = _shimmer.value;
                return CustomScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _SiteHistoryStatusHeaderSkeleton(t: t),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(left: AppSpacing.lg),
                      sliver: SliverList.builder(
                        itemCount: rowCount,
                        itemBuilder: (BuildContext context, int index) {
                          final bool isSection = index == 0 || index == 3;
                          return _SiteHistoryTimelineRowSkeleton(
                            key: Key('site-history-skeleton-row-$index'),
                            t: t,
                            isSectionHeader: isSection,
                            showLineAbove: index > 0,
                            showLineBelow: index < rowCount - 1,
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SiteHistoryStatusHeaderSkeleton extends StatelessWidget {
  const _SiteHistoryStatusHeaderSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SkeletonShimmerBox(
          width: 96,
          height: 12,
          radius: AppSpacing.radiusSm,
          t: t,
        ),
        const SizedBox(height: AppSpacing.sm),
        SiteHistoryGroupedPanel(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonShimmerBox(
                  width: 88,
                  height: 24,
                  radius: AppSpacing.radiusPill,
                  t: t,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    SkeletonShimmerBox(
                      width: 88,
                      height: 28,
                      radius: AppSpacing.radiusPill,
                      t: t,
                    ),
                    SkeletonShimmerBox(
                      width: 96,
                      height: 28,
                      radius: AppSpacing.radiusPill,
                      t: t,
                    ),
                    SkeletonShimmerBox(
                      width: 80,
                      height: 28,
                      radius: AppSpacing.radiusPill,
                      t: t,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SkeletonShimmerBox(
                  width: double.infinity,
                  height: 12,
                  radius: AppSpacing.radiusSm,
                  t: t,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SiteHistoryTimelineRowSkeleton extends StatelessWidget {
  const _SiteHistoryTimelineRowSkeleton({
    super.key,
    required this.t,
    required this.isSectionHeader,
    required this.showLineAbove,
    required this.showLineBelow,
  });

  final double t;
  final bool isSectionHeader;
  final bool showLineAbove;
  final bool showLineBelow;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SiteHistoryTimelineRail(
            showLineAbove: showLineAbove,
            showLineBelow: showLineBelow,
            node: isSectionHeader
                ? null
                : SkeletonShimmerBox(
                    width: SiteHistoryTimelineNode.size,
                    height: SiteHistoryTimelineNode.size,
                    radius: SiteHistoryTimelineNode.size / 2,
                    t: t,
                  ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                isSectionHeader ? AppSpacing.lg : AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm + 2,
              ),
              child: isSectionHeader
                  ? SkeletonShimmerBox(
                      width: 72,
                      height: 12,
                      radius: AppSpacing.radiusSm,
                      t: t,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SkeletonShimmerBox(
                          width: double.infinity,
                          height: 14,
                          radius: AppSpacing.radiusSm,
                          t: t,
                        ),
                        const SizedBox(height: AppSpacing.xxs / 2),
                        SkeletonShimmerBox(
                          width: 160,
                          height: 12,
                          radius: AppSpacing.radiusSm,
                          t: t,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
