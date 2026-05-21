library;

import 'dart:async';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/home/domain/models/co_reporter_profile.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report.dart';
import 'package:chisto_mobile/features/home/data/site_issue_report_repository.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_comment_mapping.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/pollution_site_card_sheets.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_comments_modal_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/site_detail_header_bar.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/site_detail_widgets.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/map/directions_sheet.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/site_share_result.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/take_action_coordinator.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_sheet.dart';
import 'package:chisto_mobile/shared/utils/device_platform.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_inline_banner.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/feed_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_history_providers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_tab.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_engagement_outcome_snack.dart';
import 'package:chisto_mobile/features/notifications/data/notification_inbox_actions.dart';
import 'package:chisto_mobile/features/notifications/domain/models/notification_inbox_highlight.dart';

part 'pollution_site_detail/site_detail_sheets_launcher.dart';

class PollutionSiteDetailScreen extends ConsumerStatefulWidget {
  const PollutionSiteDetailScreen({
    super.key,
    required this.site,
    this.skipInitialRefresh = false,
    this.initialTabIndex = 0,
    this.initialAction,
    this.initialHighlight,
  });

  final PollutionSite site;

  /// When true (feed/map preview), skips the automatic [getSiteById] on open.
  final bool skipInitialRefresh;
  final int initialTabIndex;

  /// When set (e.g. from notification inbox), opens comments or upvoters after load.
  final String? initialAction;

  /// Row to briefly highlight in the sheet opened via [initialAction].
  final NotificationInboxHighlight? initialHighlight;

  @override
  ConsumerState<PollutionSiteDetailScreen> createState() =>
      _PollutionSiteDetailScreenState();
}

class _PollutionSiteDetailScreenState extends ConsumerState<PollutionSiteDetailScreen>
    with StateRebuildMixin {
  late final Map<String, LatLng> _siteCoordinates;
  late final SiteIssueReportRepository _siteIssueRepo;
  late PollutionSite _site;
  bool _hasReportedIssue = false;
  List<Comment> _comments = <Comment>[];
  bool _detailRefreshFailed = false;
  bool _initialActionHandled = false;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _siteCoordinates = <String, LatLng>{};
    if (_site.latitude != null && _site.longitude != null) {
      _siteCoordinates[_site.id] = LatLng(_site.latitude!, _site.longitude!);
    }
    _siteIssueRepo = SiteIssueReportRepository();
    _comments = List<Comment>.from(_site.comments);
    _loadReportedState();
    _hydrateEngagementFromCurrentSite();
    unawaited(_bootstrapDetailState());
  }

  Future<void> _bootstrapDetailState() async {
    if (!widget.skipInitialRefresh || widget.site.firstReport == null) {
      await _refreshSiteDetails();
    }
    if (!mounted) return;
    _hydrateEngagementFromCurrentSite();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    _scheduleInitialActionIfNeeded();
  }

  void _scheduleInitialActionIfNeeded() {
    final String? action = widget.initialAction?.trim();
    if (action == null || action.isEmpty || _initialActionHandled) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialActionHandled) return;
      _initialActionHandled = true;
      unawaited(_runInitialAction(action));
    });
  }

  Future<void> _runInitialAction(String action) async {
    if (!mounted) return;
    final NotificationInboxHighlight? highlight = widget.initialHighlight;
    switch (action) {
      case NotificationInboxActions.showComments:
        await _showCommentsSheet(
          context,
          highlightCommentId: highlight?.commentId,
          highlightActorUserId: highlight?.actorUserId,
        );
      case NotificationInboxActions.showUpvoters:
        await _showUpvotersSheet(
          context,
          highlightUserId: highlight?.actorUserId,
        );
      default:
        break;
    }
  }

  void _hydrateEngagementFromCurrentSite() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(siteEngagementNotifierProvider(_site.id).notifier).hydrate(_site);
    });
  }

  Future<void> _loadReportedState() async {
    final bool reported = await _siteIssueRepo.hasReported(_site.id);
    if (mounted) setState(() => _hasReportedIssue = reported);
  }

  Future<void> _refreshSiteDetails() async {
    try {
      final PollutionSite? refreshed =
          await ref.read(sitesRepositoryProvider).getSiteById(_site.id);
      if (!mounted || refreshed == null) return;
      final double resolvedDistanceKm =
          refreshed.distanceKm >= 0 ? refreshed.distanceKm : _site.distanceKm;
      setState(() {
        _site = refreshed.copyWith(distanceKm: resolvedDistanceKm);
        _comments = List<Comment>.from(refreshed.comments);
      });
      ref.read(siteEngagementNotifierProvider(_site.id).notifier).hydrate(_site);
      if (refreshed.latitude != null && refreshed.longitude != null) {
        _siteCoordinates[refreshed.id] =
            LatLng(refreshed.latitude!, refreshed.longitude!);
      }
      _detailRefreshFailed = false;
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _detailRefreshFailed = true);
      if (e.code == 'TOO_MANY_REQUESTS') {
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _detailRefreshFailed = true);
    }
  }

  void _applyEngagementToSite() {
    final SiteEngagementState eng =
        ref.read(siteEngagementNotifierProvider(_site.id));
    setState(() {
      _site = _site.copyWith(
        score: eng.upvoteCount,
        commentsCount: eng.commentCount,
        shareCount: eng.shareCount,
        isUpvotedByMe: eng.isUpvoted,
        isSavedByMe: eng.isSaved,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final SiteEngagementState engagement =
        ref.watch(siteEngagementNotifierProvider(_site.id));
    final bool showHistoryTab = ref.watch(siteHistoryTabEnabledProvider);
    final int tabCount = showHistoryTab ? 3 : 2;
    return DefaultTabController(
      length: tabCount,
      initialIndex: widget.initialTabIndex.clamp(0, tabCount - 1),
      child: Builder(
        builder: (BuildContext tabContext) {
          return Scaffold(
            backgroundColor: AppColors.appBackground,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  SiteDetailHeaderBar(title: _site.title),
                  if (_detailRefreshFailed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        0,
                      ),
                      child: AppInlineBanner(
                        message: context.l10n.feedRefreshStaleSnack,
                        tone: AppInlineBannerTone.warning,
                      ),
                    ),
                  SiteDetailTabBar(showHistoryTab: showHistoryTab),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        PollutionSiteTab(
                          site: _site,
                          isReported: _hasReportedIssue,
                          onTakeAction: () => _openTakeActionDialog(tabContext),
                          onUpvoteTap: () => _onUpvoteTapped(tabContext),
                          isUpvotePending: engagement.isUpvoteInFlight,
                          onScoreTap: () => _showUpvotersSheet(tabContext),
                          onCommentsTap: () => _showCommentsSheet(tabContext),
                          onParticipantsTap: () => _onParticipantsTap(tabContext),
                          onDistanceTap: () => _showDirectionsSheet(tabContext),
                          onReportedTap: () => _onReportedTap(tabContext),
                          onSaveTap: () => _onSaveTapped(tabContext),
                          onReportTap: () => _openReportIssueSheet(tabContext),
                          isSaved: engagement.isSaved,
                          onShareTap: () => _onShareTap(tabContext),
                        ),
                        CleaningEventsTab(
                          site: _site,
                          onCreateEvent: _createEvent,
                        ),
                        if (showHistoryTab) SiteHistoryTab(site: _site),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

