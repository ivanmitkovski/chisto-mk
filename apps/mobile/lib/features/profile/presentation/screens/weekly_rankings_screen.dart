import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/weekly_rankings_skeleton.dart';
import 'package:chisto_mobile/shared/widgets/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:intl/intl.dart';

class WeeklyRankingsScreen extends StatefulWidget {
  const WeeklyRankingsScreen({super.key});

  @override
  State<WeeklyRankingsScreen> createState() => _WeeklyRankingsScreenState();
}

class _WeeklyRankingsScreenState extends State<WeeklyRankingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentUserRowKey = GlobalKey();

  bool _loading = true;
  AppError? _error;
  WeeklyRankingsResult? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final WeeklyRankingsResult data = await ServiceLocator
          .instance
          .profileRepository
          .getWeeklyRankings(limit: 50);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppError.network(cause: e);
        _loading = false;
      });
    }
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

  String? _weekRangeLine(BuildContext context) {
    final WeeklyRankingsResult? d = _data;
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
    final String phase = _loading && _data == null
        ? 'loading'
        : _error != null && _data == null
            ? 'error'
            : 'content';

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AnimatedPhaseSwitcher(
          phaseKey: phase,
          child: _weeklyRankingsPhaseChild(context, phase),
        ),
      ),
    );
  }

  Widget _weeklyRankingsPhaseChild(BuildContext context, String phase) {
    switch (phase) {
      case 'loading':
        return const WeeklyRankingsSkeleton();
      case 'error':
        return AppErrorView(error: _error!, onRetry: _load);
      default:
        return _buildWeeklyRankingsLoadedBody(context);
    }
  }

  Widget _buildWeeklyRankingsLoadedBody(BuildContext context) {
    final WeeklyRankingsResult data = _data!;
    final List<WeeklyLeaderboardEntry> entries = data.entries;
    final String? weekRange = _weekRangeLine(context);

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
              if (weekRange != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  weekRange,
                  style: AppTypography.cardSubtitle.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ],
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
              child: _CurrentUserRankCard(
                entry: currentUserEntry,
                onTap: _scrollToCurrentUser,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
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
                            child: _WeeklyRankingsEmpty(
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
                          child: _RankingRow(entry: entry),
                        );
                      }
                      return _RankingRow(entry: entry);
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

class _WeeklyRankingsEmpty extends StatelessWidget {
  const _WeeklyRankingsEmpty({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 30,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.emptyStateTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.authSubtitle.copyWith(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.35,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentUserRankCard extends StatelessWidget {
  const _CurrentUserRankCard({
    required this.entry,
    required this.onTap,
  });

  final WeeklyLeaderboardEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panelBackground,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.radius14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryDark,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          context.l10n.profileWeeklyRankingsYouRank(entry.rank),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.radiusSm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusCircle,
                            ),
                          ),
                          child: Text(
                            context.l10n.profileWeeklyRankingsYouBadge,
                            style: AppTypography.badgeLabel.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.profileWeeklyRankingsPtsThisWeek(
                        entry.weeklyPoints,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
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

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final WeeklyLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool isTopThree = entry.rank <= 3;
    final bool isCurrentUser = entry.isCurrentUser;
    final String initial = entry.displayName.isNotEmpty
        ? entry.displayName[0].toUpperCase()
        : '?';

    IconData? leadingIcon;
    Color iconColor = AppColors.textMuted;
    if (entry.rank == 1) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.accentWarning;
    } else if (entry.rank == 2) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.textMuted;
    } else if (entry.rank == 3) {
      leadingIcon = Icons.emoji_events_rounded;
      iconColor = AppColors.accentWarningDark;
    }

    Color backgroundColor = isCurrentUser
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.panelBackground;
    Color borderColor = isCurrentUser
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.divider.withValues(alpha: 0.9);

    return Semantics(
      label: context.l10n.profileWeeklyRankingsRowSemantic(
        entry.rank,
        entry.displayName,
        entry.weeklyPoints,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: AppSpacing.xl,
              child: Center(
                child: isTopThree && leadingIcon != null
                    ? Icon(
                        leadingIcon,
                        size: AppSpacing.iconMd,
                        color: iconColor,
                      )
                    : Text(
                        '${entry.rank}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: AppSpacing.radius18,
              backgroundColor: AppColors.inputFill,
              child: Text(
                initial,
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${entry.weeklyPoints}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
