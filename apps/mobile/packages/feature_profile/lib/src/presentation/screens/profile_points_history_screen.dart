import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/theme/app_colors.dart';
import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:chisto_infrastructure/core/theme/app_typography.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/no_overscroll_overlay_scroll_behavior.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/animated_phase_switcher.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:feature_profile/src/domain/models/points_history_page.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/presentation/providers/points_history_notifier.dart';
import 'package:feature_profile/src/presentation/utils/points_history_reason_display.dart';
import 'package:feature_profile/src/presentation/widgets/points_history_activity_tile.dart';
import 'package:feature_profile/src/presentation/widgets/points_history_milestone_chip.dart';
import 'package:feature_profile/src/presentation/widgets/points_history_summary_strip.dart';
import 'package:feature_profile/src/presentation/widgets/profile_points_history_skeleton.dart';
import 'package:feature_profile/src/presentation/widgets/profile_scroll_bottom_shadow_clipper.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

sealed class _HistoryListEntry {
  const _HistoryListEntry();
}

final class _DateHeaderEntry extends _HistoryListEntry {
  const _DateHeaderEntry(this.day);
  final DateTime day;
}

final class _ActivityRowEntry extends _HistoryListEntry {
  const _ActivityRowEntry(this.entry);
  final PointsHistoryEntry entry;
}

class ProfilePointsHistoryScreen extends ConsumerStatefulWidget {
  const ProfilePointsHistoryScreen({super.key, required this.summaryUser});

  final ProfileUser summaryUser;

  @override
  ConsumerState<ProfilePointsHistoryScreen> createState() =>
      _ProfilePointsHistoryScreenState();
}

class _ProfilePointsHistoryScreenState
    extends ConsumerState<ProfilePointsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pointsHistoryNotifierProvider.notifier).loadInitial();
    });
  }

  bool _onScrollNotification(ScrollNotification n) {
    final PointsHistoryUiState s = ref.read(pointsHistoryNotifierProvider);
    if (s.phase != PointsHistoryPhase.ready) return false;
    if (n.metrics.axis != Axis.vertical) return false;
    if (s.loadingMore || s.nextCursor == null || s.loadMoreError != null) {
      return false;
    }
    final double maxExtent = n.metrics.maxScrollExtent;
    if (!maxExtent.isFinite || maxExtent <= 0) return false;
    if (n.metrics.pixels >= maxExtent - 220) {
      ref.read(pointsHistoryNotifierProvider.notifier).loadMore();
    }
    return false;
  }

  List<_HistoryListEntry> _buildFlatList(List<PointsHistoryEntry> entries) {
    if (entries.isEmpty) return <_HistoryListEntry>[];
    final List<_HistoryListEntry> out = <_HistoryListEntry>[];
    DateTime? lastDay;
    for (final PointsHistoryEntry e in entries) {
      final DateTime day = DateTime(
        e.createdAt.year,
        e.createdAt.month,
        e.createdAt.day,
      );
      if (lastDay == null || day != lastDay) {
        lastDay = day;
        out.add(_DateHeaderEntry(day));
      }
      out.add(_ActivityRowEntry(e));
    }
    return out;
  }

  String _timeLine(BuildContext context, DateTime t) {
    final String loc = Localizations.localeOf(context).toString();
    return DateFormat.jm(loc).format(t.toLocal());
  }

  String _dayHeader(BuildContext context, DateTime day) {
    final String loc = Localizations.localeOf(context).toString();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (day == today) {
      return context.l10n.profilePointsHistoryDayToday;
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return context.l10n.profilePointsHistoryDayYesterday;
    }
    return DateFormat.yMMMd(loc).format(day);
  }

  @override
  Widget build(BuildContext context) {
    final PointsHistoryUiState state = ref.watch(pointsHistoryNotifierProvider);

    final String phase =
        state.phase == PointsHistoryPhase.loading && state.entries.isEmpty
        ? 'loading'
        : state.phase == PointsHistoryPhase.error && state.entries.isEmpty
        ? 'error'
        : 'content';

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: AnimatedPhaseSwitcher(
          phaseKey: phase,
          child: _pointsHistoryPhaseChild(context, state, phase),
        ),
      ),
    );
  }

  Widget _pointsHistoryPhaseChild(
    BuildContext context,
    PointsHistoryUiState state,
    String phase,
  ) {
    switch (phase) {
      case 'loading':
        return const ProfilePointsHistorySkeleton();
      case 'error':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _pointsHistoryHeader(context),
            Expanded(
              child: AppErrorView(
                error: state.pageError!,
                onRetry: () => ref
                    .read(pointsHistoryNotifierProvider.notifier)
                    .loadInitial(),
              ),
            ),
          ],
        );
      default:
        return _buildPointsHistoryLoadedBody(context, state);
    }
  }

  Widget _pointsHistoryHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: ProfileSubScreenHeader(
        title: context.l10n.profilePointsHistoryTitle,
        subtitle: context.l10n.profilePointsHistorySubtitle,
      ),
    );
  }

  Widget _buildPointsHistoryLoadedBody(
    BuildContext context,
    PointsHistoryUiState state,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ProfileUser u = widget.summaryUser;
    final List<PointsHistoryMilestone> milestonesNewestFirst =
        List<PointsHistoryMilestone>.of(state.milestones.reversed);
    final List<_HistoryListEntry> flat = _buildFlatList(state.entries);

    final bool showLoadMoreError = state.loadMoreError != null;
    final bool showLoadingFooter =
        state.loadingMore && state.nextCursor != null && !showLoadMoreError;
    final int footerCount =
        (showLoadMoreError ? 1 : 0) + (showLoadingFooter ? 1 : 0);

    final List<Widget> slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: PointsHistorySummaryStrip(user: u),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      if (milestonesNewestFirst.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              0,
              AppSpacing.sm,
            ),
            child: Text(
              context.l10n.profilePointsHistoryMilestonesSection,
              style: AppTypography.cardSubtitle(textTheme).copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.05,
              ),
            ),
          ),
        ),
      if (milestonesNewestFirst.isNotEmpty)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              itemCount: milestonesNewestFirst.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int i) {
                final PointsHistoryMilestone m = milestonesNewestFirst[i];
                return PointsHistoryMilestoneChip(milestone: m);
              },
            ),
          ),
        ),
      if (milestonesNewestFirst.isNotEmpty)
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            context.l10n.profilePointsHistoryActivitySection,
            style: AppTypography.cardSubtitle(textTheme).copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.05,
            ),
          ),
        ),
      ),
      if (flat.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Semantics(
            container: true,
            label:
                '${context.l10n.profilePointsHistoryActivitySection}. ${context.l10n.profilePointsHistoryEmpty}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Center(
                child: Text(
                  context.l10n.profilePointsHistoryEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypographySurfaces.homeMutedCaption(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            if (index >= flat.length) {
              if (showLoadMoreError) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label:
                        '${context.l10n.profilePointsHistoryLoadMoreErrorTitle}. ${localizedAppErrorMessage(l10n, state.loadMoreError!)}',
                    child: Material(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                context
                                    .l10n
                                    .profilePointsHistoryLoadMoreErrorTitle,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            AppButton.text(
                              label: context
                                  .l10n
                                  .profilePointsHistoryLoadMoreRetry,
                              onPressed: () {
                                ref
                                    .read(
                                      pointsHistoryNotifierProvider.notifier,
                                    )
                                    .loadMore();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: AppLoadingIndicator(
                      size: AppLoadingIndicatorSize.sm,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              );
            }
            final _HistoryListEntry row = flat[index];
            switch (row) {
              case _DateHeaderEntry(:final DateTime day):
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    index == 0 ? 0 : AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    _dayHeader(context, day),
                    style: AppTypographySurfaces.profilePointsHistoryDayHeader(
                      Theme.of(context).textTheme,
                    ),
                  ),
                );
              case _ActivityRowEntry(:final PointsHistoryEntry entry):
                final String reasonTitle = pointsHistoryReasonTitle(
                  l10n,
                  entry.reasonCode,
                );
                final String deltaLabel = pointsHistoryDeltaLabel(
                  l10n,
                  entry.delta,
                );
                final String timeLine = _timeLine(context, entry.createdAt);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: PointsHistoryActivityTile(
                    entry: entry,
                    reasonTitle: reasonTitle,
                    reasonIcon: pointsHistoryReasonIcon(entry.reasonCode),
                    deltaLabel: deltaLabel,
                    timeLine: timeLine,
                    semanticLabel: context.l10n.profilePointsActivityRowSemantic(
                      reasonTitle,
                      timeLine,
                      deltaLabel,
                    ),
                  ),
                );
            }
          }, childCount: flat.length + footerCount),
        ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.xl + AppSpacing.lg),
      ),
    ];

    return Semantics(
      namesRoute: true,
      label: context.l10n.profilePointsHistoryTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _pointsHistoryHeader(context),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: ScrollConfiguration(
                behavior: const NoOverscrollOverlayScrollBehavior(),
                child: ClipRect(
                  clipper: const ProfileScrollBottomShadowClipper(
                    bottomExtension: kProfileScrollBottomShadowExtension,
                  ),
                  child: AppRefreshIndicator(
                    onRefresh: () => ref
                        .read(pointsHistoryNotifierProvider.notifier)
                        .refresh(),
                    child: CustomScrollView(
                      clipBehavior: Clip.none,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: slivers,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
