import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/utils/profile_level_tier.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_points_history_skeleton.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
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

class ProfilePointsHistoryScreen extends StatefulWidget {
  const ProfilePointsHistoryScreen({super.key, required this.summaryUser});

  final ProfileUser summaryUser;

  @override
  State<ProfilePointsHistoryScreen> createState() =>
      _ProfilePointsHistoryScreenState();
}

class _ProfilePointsHistoryScreenState extends State<ProfilePointsHistoryScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  AppError? _error;
  final List<PointsHistoryEntry> _entries = <PointsHistoryEntry>[];
  List<PointsHistoryMilestone> _milestones = <PointsHistoryMilestone>[];
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  /// Uses [ScrollNotification] instead of a [ScrollController] so this screen
  /// stays valid while [AnimatedPhaseSwitcher] briefly stacks two phases:
  /// a controller must never attach to two scroll views at once.
  bool _onScrollNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (_loadingMore || _nextCursor == null || _error != null) return false;
    final double maxExtent = n.metrics.maxScrollExtent;
    if (!maxExtent.isFinite || maxExtent <= 0) return false;
    if (n.metrics.pixels >= maxExtent - 220) {
      _loadMore();
    }
    return false;
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _entries.clear();
      _milestones = <PointsHistoryMilestone>[];
      _nextCursor = null;
    });
    try {
      final PointsHistoryPage page = await ServiceLocator.instance.profileRepository
          .getPointsHistory(limit: 30);
      if (!mounted) return;
      setState(() {
        _entries.addAll(page.items);
        _milestones = List<PointsHistoryMilestone>.of(page.milestones);
        _nextCursor = page.nextCursor;
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

  Future<void> _loadMore() async {
    final String? cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final PointsHistoryPage page = await ServiceLocator.instance.profileRepository
          .getPointsHistory(limit: 30, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _entries.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  List<_HistoryListEntry> _buildFlatList() {
    if (_entries.isEmpty) return <_HistoryListEntry>[];
    final List<_HistoryListEntry> out = <_HistoryListEntry>[];
    DateTime? lastDay;
    for (final PointsHistoryEntry e in _entries) {
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

  String _reasonTitle(AppLocalizations l10n, String code) {
    switch (code) {
      case 'FIRST_REPORT':
        return l10n.profilePointsReasonFirstReport;
      case 'REPORT_APPROVED':
        return l10n.profilePointsReasonReportApproved;
      case 'REPORT_APPROVAL_REVOKED':
        return l10n.profilePointsReasonReportApprovalRevoked;
      case 'REPORT_SUBMITTED':
        return l10n.profilePointsReasonReportSubmitted;
      case 'ECO_ACTION_APPROVED':
        return l10n.profilePointsReasonEcoApproved;
      case 'ECO_ACTION_REALIZED':
        return l10n.profilePointsReasonEcoRealized;
      case 'EVENT_ORGANIZER_APPROVED':
        return l10n.profilePointsReasonEventOrganizerApproved;
      case 'EVENT_JOINED':
        return l10n.profilePointsReasonEventJoined;
      case 'EVENT_JOIN_NO_SHOW':
        return l10n.profilePointsReasonEventJoinNoShow;
      case 'EVENT_CHECK_IN':
        return l10n.profilePointsReasonEventCheckIn;
      case 'EVENT_COMPLETED':
        return l10n.profilePointsReasonEventCompleted;
      default:
        return l10n.profilePointsReasonOther;
    }
  }

  IconData _reasonIcon(String code) {
    switch (code) {
      case 'FIRST_REPORT':
        return Icons.assignment_turned_in_outlined;
      case 'REPORT_APPROVED':
        return Icons.verified_outlined;
      case 'REPORT_APPROVAL_REVOKED':
        return Icons.undo_rounded;
      case 'REPORT_SUBMITTED':
        return Icons.outbox_outlined;
      case 'ECO_ACTION_APPROVED':
      case 'ECO_ACTION_REALIZED':
        return Icons.volunteer_activism_outlined;
      case 'EVENT_ORGANIZER_APPROVED':
        return Icons.verified_outlined;
      case 'EVENT_JOINED':
        return Icons.event_available_outlined;
      case 'EVENT_JOIN_NO_SHOW':
        return Icons.event_busy_outlined;
      case 'EVENT_CHECK_IN':
        return Icons.qr_code_scanner_outlined;
      case 'EVENT_COMPLETED':
        return Icons.flag_outlined;
      default:
        return Icons.stars_rounded;
    }
  }

  String _deltaLabel(AppLocalizations l10n, int delta) {
    if (delta >= 0) {
      return l10n.profilePointsDeltaPositive(delta);
    }
    return l10n.profilePointsDeltaNegative(delta);
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
    final String phase = _loading && _entries.isEmpty
        ? 'loading'
        : _error != null && _entries.isEmpty
            ? 'error'
            : 'content';

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AnimatedPhaseSwitcher(
          phaseKey: phase,
          child: _pointsHistoryPhaseChild(context, phase),
        ),
      ),
    );
  }

  Widget _pointsHistoryPhaseChild(BuildContext context, String phase) {
    switch (phase) {
      case 'loading':
        return const ProfilePointsHistorySkeleton();
      case 'error':
        return AppErrorView(error: _error!, onRetry: _loadInitial);
      default:
        return _buildPointsHistoryLoadedBody(context);
    }
  }

  Widget _buildPointsHistoryLoadedBody(BuildContext context) {
    final ProfileUser u = widget.summaryUser;
    final List<PointsHistoryMilestone> milestonesNewestFirst =
        List<PointsHistoryMilestone>.of(_milestones.reversed);
    final List<_HistoryListEntry> flat = _buildFlatList();

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
                context.l10n.profilePointsHistoryTitle,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.profilePointsHistorySubtitle,
                style: AppTypography.cardSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                  letterSpacing: -0.05,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _SummaryStrip(user: u),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadInitial,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
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
                        style: AppTypography.cardSubtitle.copyWith(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: milestonesNewestFirst.length,
                        separatorBuilder:
                            (BuildContext context, int index) =>
                                const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (BuildContext context, int i) {
                          final PointsHistoryMilestone m =
                              milestonesNewestFirst[i];
                          return _MilestoneChip(milestone: m);
                        },
                      ),
                    ),
                  ),
                if (milestonesNewestFirst.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
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
                      style: AppTypography.cardSubtitle.copyWith(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Center(
                        child: Text(
                          context.l10n.profilePointsHistoryEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        if (index >= flat.length) {
                          if (_loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            );
                          case _ActivityRowEntry(:final PointsHistoryEntry entry):
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.xs,
                              ),
                              child: _ActivityTile(
                                entry: entry,
                                reasonTitle: _reasonTitle(
                                  AppLocalizations.of(context)!,
                                  entry.reasonCode,
                                ),
                                reasonIcon: _reasonIcon(entry.reasonCode),
                                deltaLabel: _deltaLabel(
                                  AppLocalizations.of(context)!,
                                  entry.delta,
                                ),
                                timeLine: _timeLine(context, entry.createdAt),
                              ),
                            );
                        }
                      },
                      childCount:
                          flat.length +
                          (_loadingMore && _nextCursor != null ? 1 : 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.user});

  final ProfileUser user;

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
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
            ),
            child: Icon(
              profileTierIcon(user.levelTierKey),
              color: AppColors.primaryDark,
              size: AppSpacing.iconLg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profileMilestoneTierTitle(
                    context,
                    level: user.level,
                    levelTierKey: user.levelTierKey,
                    levelDisplayName: user.levelDisplayName,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.profileLifetimeXpOnBar(user.totalPointsEarned),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.milestone});

  final PointsHistoryMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final String title = profileMilestoneTierTitle(
      context,
      level: milestone.level,
      levelTierKey: milestone.levelTierKey,
      levelDisplayName: milestone.levelDisplayName,
    );
    final String loc = Localizations.localeOf(context).toString();
    final String when = DateFormat.MMMd(loc).format(
      milestone.reachedAt.toLocal(),
    );

    return Container(
      width: 168,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.primaryDark.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
            ),
            child: Text(
              context.l10n.profilePointsHistoryLevelUpBadge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 9,
                  ),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
          ),
          Text(
            when,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.entry,
    required this.reasonTitle,
    required this.reasonIcon,
    required this.deltaLabel,
    required this.timeLine,
  });

  final PointsHistoryEntry entry;
  final String reasonTitle;
  final IconData reasonIcon;
  final String deltaLabel;
  final String timeLine;

  @override
  Widget build(BuildContext context) {
    final Color deltaColor =
        entry.delta >= 0 ? AppColors.primaryDark : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
              ),
              child: Icon(
                reasonIcon,
                color: AppColors.primaryDark,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    reasonTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeLine,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              deltaLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
