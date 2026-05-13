import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/weekly_rankings_notifier.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_sub_screen_header.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/weekly_current_user_card.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/weekly_ranking_row.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/weekly_rankings_empty.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/weekly_rankings_skeleton.dart';
import 'package:chisto_mobile/shared/widgets/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_refresh_indicator.dart';
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
    AppHaptics.tap();
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

    if (startLocal.year == endLocal.year && startLocal.month == endLocal.month) {
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

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WeeklyRankingsResult> asyncRankings =
        ref.watch(weeklyRankingsNotifierProvider);

    final String phase = asyncRankings.when(
      data: (_) => 'content',
      error: (Object _, StackTrace _) => 'error',
      loading: () => 'loading',
    );

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AnimatedPhaseSwitcher(
          phaseKey: phase,
          child: asyncRankings.when(
            skipLoadingOnReload: true,
            data: (WeeklyRankingsResult data) =>
                _buildWeeklyRankingsLoadedBody(context, data),
            loading: () => const WeeklyRankingsSkeleton(),
            error: (Object e, StackTrace _) {
              final AppError err =
                  e is AppError ? e : AppError.network(cause: e);
              return AppErrorView(
                error: err,
                onRetry: () => ref
                    .read(weeklyRankingsNotifierProvider.notifier)
                    .refresh(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyRankingsLoadedBody(
    BuildContext context,
    WeeklyRankingsResult data,
  ) {
    final List<WeeklyLeaderboardEntry> entries = data.entries;
    final String? weekRange = _weekRangeLine(context, data);

    WeeklyLeaderboardEntry? currentUserEntry;
    try {
      currentUserEntry = entries.firstWhere(
        (WeeklyLeaderboardEntry e) => e.isCurrentUser,
      );
    } catch (_) {
      currentUserEntry = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: ProfileSubScreenHeader(
            title: context.l10n.profileWeeklyRankingsTitle,
            subtitle: context.l10n.profileWeeklyRankingsSubtitle,
            belowSubtitle: weekRange != null
                ? Text(
                    weekRange,
                    style: AppTypography.cardSubtitle.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  )
                : null,
          ),
        ),
        if (entries.isNotEmpty) ...<Widget>[
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
        ],
        if (currentUserEntry != null)
          Padding(
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
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () =>
                ref.read(weeklyRankingsNotifierProvider.notifier).refresh(),
            child: entries.isEmpty
                ? LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: WeeklyRankingsEmpty(
                              title: context
                                  .l10n.profileWeeklyRankingsEmptyTitle,
                              subtitle: context
                                  .l10n.profileWeeklyRankingsEmptySubtitle,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final WeeklyLeaderboardEntry entry = entries[index];
                      if (entry.isCurrentUser) {
                        return KeyedSubtree(
                          key: _currentUserRowKey,
                          child: WeeklyRankingRow(entry: entry),
                        );
                      }
                      return WeeklyRankingRow(entry: entry);
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemCount: entries.length,
                  ),
          ),
        ),
      ],
    );
  }
}
