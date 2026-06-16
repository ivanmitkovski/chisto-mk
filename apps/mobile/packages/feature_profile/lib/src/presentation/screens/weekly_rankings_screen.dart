import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/theme/app_colors.dart';
import 'package:chisto_infrastructure/core/theme/app_motion.dart';
import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:chisto_infrastructure/core/theme/app_typography.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/no_overscroll_overlay_scroll_behavior.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/animated_phase_switcher.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:feature_profile/src/domain/models/weekly_rankings_result.dart';
import 'package:feature_profile/src/presentation/providers/weekly_rankings_notifier.dart';
import 'package:feature_profile/src/presentation/widgets/profile_scroll_bottom_shadow_clipper.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_header.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_panel.dart';
import 'package:feature_profile/src/presentation/widgets/weekly_current_user_card.dart';
import 'package:feature_profile/src/presentation/widgets/weekly_ranking_row.dart';
import 'package:feature_profile/src/presentation/widgets/weekly_rankings_empty.dart';
import 'package:feature_profile/src/presentation/widgets/weekly_rankings_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WeeklyRankingsScreen extends ConsumerStatefulWidget {
  const WeeklyRankingsScreen({super.key});

  @override
  ConsumerState<WeeklyRankingsScreen> createState() =>
      _WeeklyRankingsScreenState();
}

class _WeeklyRankingsScreenState extends ConsumerState<WeeklyRankingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentUserRowKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentUser() {
    final BuildContext? rowContext = _currentUserRowKey.currentContext;
    if (rowContext == null) return;
    Scrollable.ensureVisible(
      rowContext,
      duration: AppMotion.emphasizedDuration,
      curve: AppMotion.decelerate,
      alignment: 0.3,
    );
  }

  /// Single typographic en dash (U+2013); avoids `--` from spaced hyphen + locale formats.
  static const String _enDash = '\u2013';

  String? _weekRangeLine(BuildContext context, WeeklyRankingsResult? d) {
    if (d == null) return null;
    final DateTime? startUtc = DateTime.tryParse(d.weekStartsAt);
    final DateTime? endUtc = DateTime.tryParse(d.weekEndsAt);
    if (startUtc == null || endUtc == null) return null;
    final DateTime startLocal = startUtc.toLocal();
    final DateTime endLocal = endUtc.toLocal();
    final String loc = Localizations.localeOf(context).toString();
    final int nowYear = DateTime.now().year;

    if (startLocal.year == endLocal.year &&
        startLocal.month == endLocal.month) {
      final String month = DateFormat.MMM(loc).format(startLocal);
      final String span = '$month ${startLocal.day}$_enDash${endLocal.day}';
      if (startLocal.year != nowYear) {
        return '$span, ${startLocal.year}';
      }
      return span;
    }

    final String left = DateFormat.MMMd(loc).format(startLocal);
    final String right = startLocal.year == endLocal.year
        ? DateFormat.MMMd(loc).format(endLocal)
        : DateFormat.yMMMd(loc).format(endLocal);
    return '$left $_enDash $right';
  }

  String _phaseFor(AsyncValue<WeeklyRankingsResult> asyncRankings) {
    if (asyncRankings.hasValue) return 'content';
    if (asyncRankings.isLoading) return 'loading';
    return 'error';
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WeeklyRankingsResult> asyncRankings = ref.watch(
      weeklyRankingsNotifierProvider,
    );

    final String phase = _phaseFor(asyncRankings);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: AnimatedPhaseSwitcher(
          phaseKey: phase,
          child: asyncRankings.when(
            skipLoadingOnReload: true,
            data: (WeeklyRankingsResult data) =>
                _buildWeeklyRankingsLoadedBody(context, data),
            loading: () => const WeeklyRankingsSkeleton(),
            error: (Object e, StackTrace _) {
              final AppError err = e is AppError
                  ? e
                  : AppError.network(cause: e);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _weeklyRankingsHeader(context, weekRange: null),
                  Expanded(
                    child: AppErrorView(
                      error: err,
                      onRetry: () => ref
                          .read(weeklyRankingsNotifierProvider.notifier)
                          .refresh(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _weeklyRankingsHeader(
    BuildContext context, {
    required String? weekRange,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: ProfileSubScreenHeader(
        title: context.l10n.profileWeeklyRankingsTitle,
        subtitle: context.l10n.profileWeeklyRankingsSubtitle,
        belowSubtitle: weekRange != null
            ? Text(
                weekRange,
                style: AppTypography.cardSubtitle(textTheme).copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildWeeklyRankingsLoadedBody(
    BuildContext context,
    WeeklyRankingsResult data,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<WeeklyLeaderboardEntry> entries = data.entries;
    final String? weekRange = _weekRangeLine(context, data);
    final double listBottomPadding = ProfileSubScreenPanel.scrollBottomPadding(
      context,
    );

    WeeklyLeaderboardEntry? currentUserEntry;
    try {
      currentUserEntry = entries.firstWhere(
        (WeeklyLeaderboardEntry e) => e.isCurrentUser,
      );
    } catch (_) {
      currentUserEntry = null;
    }

    final List<Widget> slivers = <Widget>[
      if (entries.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              context.l10n.profileWeeklyRankingsTopSupporters,
              style: AppTypography.cardSubtitle(textTheme).copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.05,
              ),
            ),
          ),
        ),
      if (currentUserEntry != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Semantics(
              button: true,
              hint: context.l10n.profileWeeklyRankingsScrollToYouHint,
              child: WeeklyCurrentUserCard(
                entry: currentUserEntry,
                onTap: _scrollToCurrentUser,
              ),
            ),
          ),
        ),
      if (entries.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: WeeklyRankingsEmpty(
              title: context.l10n.profileWeeklyRankingsEmptyTitle,
              subtitle: context.l10n.profileWeeklyRankingsEmptySubtitle,
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final WeeklyLeaderboardEntry entry = entries[index];
              final Widget row = entry.isCurrentUser
                  ? KeyedSubtree(
                      key: _currentUserRowKey,
                      child: WeeklyRankingRow(entry: entry),
                    )
                  : WeeklyRankingRow(entry: entry);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == entries.length - 1
                      ? listBottomPadding
                      : AppSpacing.xs,
                ),
                child: row,
              );
            }, childCount: entries.length),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _weeklyRankingsHeader(context, weekRange: weekRange),
        Expanded(
          child: ScrollConfiguration(
            behavior: const NoOverscrollOverlayScrollBehavior(),
            child: ClipRect(
              clipper: const ProfileScrollBottomShadowClipper(
                bottomExtension: kProfileScrollBottomShadowExtension,
              ),
              child: AppRefreshIndicator(
                onRefresh: () =>
                    ref.read(weeklyRankingsNotifierProvider.notifier).refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
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
      ],
    );
  }
}
