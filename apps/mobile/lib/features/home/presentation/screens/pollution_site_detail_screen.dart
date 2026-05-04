import 'dart:async';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/home/domain/models/co_reporter_profile.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report.dart';
import 'package:chisto_mobile/features/home/data/site_issue_report_repository.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_comment_mapping.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_comments_modal_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/upvoters_sheet_content.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/site_detail_widgets.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/map/directions_sheet.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/site_share_result.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/take_action_coordinator.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/device_platform.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/feed_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_engagement_outcome_snack.dart';

class PollutionSiteDetailScreen extends ConsumerStatefulWidget {
  const PollutionSiteDetailScreen({
    super.key,
    required this.site,
    this.initialTabIndex = 0,
  });

  final PollutionSite site;
  final int initialTabIndex;

  @override
  ConsumerState<PollutionSiteDetailScreen> createState() =>
      _PollutionSiteDetailScreenState();
}

class _PollutionSiteDetailScreenState extends ConsumerState<PollutionSiteDetailScreen> {
  late final Map<String, LatLng> _siteCoordinates;
  late final SiteIssueReportRepository _siteIssueRepo;
  late PollutionSite _site;
  bool _hasReportedIssue = false;
  List<Comment> _comments = <Comment>[];
  bool _detailRefreshFailed = false;

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
    await _refreshSiteDetails();
    if (!mounted) return;
    _hydrateEngagementFromCurrentSite();
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
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      child: Builder(
        builder: (BuildContext tabContext) {
          return Scaffold(
            backgroundColor: AppColors.appBackground,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  _buildHeader(tabContext),
                  if (_detailRefreshFailed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accentDanger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          context.l10n.feedRefreshStaleSnack,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  _buildTabs(tabContext),
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

  Future<void> _createEvent() async {
    try {
      AppHaptics.softTransition();
      final EcoEvent? createdEvent = await EventsNavigation.openCreate(
        context,
        preselectedSiteId: _site.id,
        preselectedSiteName: _site.title,
        preselectedSiteImageUrl:
            _site.primaryImageUrl != null && _site.primaryImageUrl!.trim().isNotEmpty
                ? _site.primaryImageUrl!.trim()
                : 'assets/images/references/onboarding_reference.png',
        preselectedSiteDistanceKm: _site.distanceKm.toDouble(),
      );
      if (createdEvent == null || !mounted) return;
      await EventsNavigation.openDetail(context, eventId: createdEvent.id);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.eventsOfflineSyncFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _openTakeActionDialog(BuildContext context) async {
    final TakeActionType? action = await TakeActionSheet.show(context);
    if (action == null || !context.mounted) return;
    final TakeActionCoordinatorOutcome outcome = await TakeActionCoordinator.execute(
      context,
      action: action,
      site: _site,
      isFromSiteDetail: true,
      onSwitchToCleaningTab: () {
        DefaultTabController.of(context).animateTo(1);
      },
    );
    if (!mounted) return;
    if (action == TakeActionType.shareSite && outcome is TakeActionCoordinatorShareOutcome) {
      _applyShareCoordinatorOutcome(outcome.share);
    }
  }

  Future<void> _openReportIssueSheet(BuildContext context) async {
    final l10n = context.l10n;
    await ref.read(sitesRepositoryProvider).trackFeedEvent(
      _site.id,
      eventType: 'cta_report_issue_opened',
    );
    if (!context.mounted) return;
    final bool? reported = await ReportIssueSheet.show(
      context,
      site: _site,
      repository: _siteIssueRepo,
    );
    if (!context.mounted) return;
    if (reported == true) {
      setState(() => _hasReportedIssue = true);
      AppSnack.show(
        context,
        message: l10n.siteDetailThankYouReportSnack,
        type: AppSnackType.success,
      );
    }
  }

  Future<void> _onSaveTapped(BuildContext context) async {
    final SiteEngagementOutcome outcome = await ref
        .read(siteEngagementNotifierProvider(_site.id).notifier)
        .toggleSave();
    if (!mounted) return;
    _applyEngagementToSite();
    if (!context.mounted) return;
    if (outcome.isSuccess ||
        outcome.kind == SiteEngagementOutcomeKind.queuedOffline) {
      ref.read(feedSitesNotifierProvider.notifier).patchSiteSaved(
            _site.id,
            ref.read(siteEngagementNotifierProvider(_site.id)).isSaved,
          );
    }
    if (outcome.isSuccess) {
      final bool nowSaved =
          ref.read(siteEngagementNotifierProvider(_site.id)).isSaved;
      AppHaptics.success(context);
      AppSnack.show(
        context,
        message: nowSaved
            ? context.l10n.siteDetailSaveAddedSnack
            : context.l10n.siteDetailSaveRemovedSnack,
        type: AppSnackType.success,
      );
      return;
    }
    showSiteEngagementOutcomeSnack(
      context,
      outcome,
      genericFailureMessage: context.l10n.siteCardSavedFailedSnack,
    );
  }

  Future<void> _onUpvoteTapped(BuildContext context) async {
    if (!context.mounted) return;
    // Immediate selection-style tap (server success is separate; notifier is optimistic).
    AppHaptics.tap(context);
    final SiteEngagementOutcome outcome = await ref
        .read(siteEngagementNotifierProvider(_site.id).notifier)
        .toggleUpvote();
    if (!mounted) return;
    _applyEngagementToSite();
    if (!context.mounted) return;
    if (outcome.isSuccess) {
      // Subtle second pulse only when ending in upvoted state (add), not on remove — avoids double-buzz noise.
      if (ref.read(siteEngagementNotifierProvider(_site.id)).isUpvoted) {
        AppHaptics.light(context);
      }
      return;
    }
    if (outcome.kind == SiteEngagementOutcomeKind.failure) {
      AppHaptics.medium();
    }
    showSiteEngagementOutcomeSnack(
      context,
      outcome,
      genericFailureMessage: context.l10n.siteDetailUpvoteFailedSnack,
    );
  }

  Future<void> _onShareTap(BuildContext context) async {
    final TakeActionCoordinatorOutcome outcome = await TakeActionCoordinator.execute(
      context,
      action: TakeActionType.shareSite,
      site: _site,
      isFromSiteDetail: true,
    );
    if (!mounted) return;
    if (outcome is TakeActionCoordinatorShareOutcome) {
      _applyShareCoordinatorOutcome(outcome.share);
    }
  }

  void _applyShareCoordinatorOutcome(SiteShareResult share) {
    switch (share) {
      case SiteShareSuccess(:final snapshot):
        ref.read(siteEngagementNotifierProvider(_site.id).notifier).setShareCount(snapshot.sharesCount);
        _applyEngagementToSite();
      case SiteShareCancelled():
      case SiteShareTrackFailed():
        break;
    }
  }

  Future<void> _onReportedTap(BuildContext context) async {
    final SiteReport? report = _site.firstReport;
    if (report == null) return;
    AppHaptics.tap();
    await FirstReportModal.show(context, report);
  }

  Future<void> _onParticipantsTap(BuildContext context) async {
    final List<CoReporterProfile> coReporters = _site.displayCoReporterProfiles;
    AppHaptics.tap();
    if (coReporters.isNotEmpty) {
      await CoReportersModal.show(context, coReporters);
    } else if (_site.mergedDuplicateChildCountTotal > 0) {
      await MergedDuplicateSubmissionsModal.show(
        context,
        count: _site.mergedDuplicateChildCountTotal,
      );
    } else {
      AppSnack.show(
        context,
        message: context.l10n.siteDetailNoCoReportersSnack,
        type: AppSnackType.info,
      );
    }
  }

  Future<void> _showCommentsSheet(BuildContext context) async {
    AppHaptics.tap();
    final l10n = context.l10n;
    Future<List<Comment>> loadComments(String sort) async {
      final result = await ref.read(sitesRepositoryProvider).getSiteComments(
        _site.id,
        sort: sort,
      );
      return result.items.map(commentFromSiteCommentItem).toList();
    }
    try {
      final comments = await loadComments('top');
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: l10n.commentsPrefetchCouldNotRefreshSnack,
          type: AppSnackType.info,
        );
      }
    }
    if (!context.mounted) return;
    await showPollutionSiteCommentsModalBottomSheet(
      context,
      builder: (BuildContext sheetContext, ScrollController scrollController) {
        return CommentsBottomSheet(
          siteId: _site.id,
          comments: _comments,
          siteTitle: _site.title,
          scrollController: scrollController,
          onCommentsCountChanged: (int count) {
            if (!mounted) return;
            setState(() {
              _site = _site.copyWith(commentsCount: count);
            });
          },
          onCommentsChanged: (comments) {
            if (!mounted) return;
            setState(() => _comments = comments);
          },
          onLoadMoreDirectReplies:
              (String parentId, int page, String sort) async {
            final SiteCommentsResult result =
                await ref.read(sitesRepositoryProvider).getSiteComments(
              _site.id,
              parentId: parentId,
              page: page,
              limit: 20,
              sort: sort,
            );
            return result.items.map(commentFromSiteCommentItem).toList();
          },
          onCommentSubmitted: (String text, String? parentId) {
            return ref.read(sitesRepositoryProvider).createSiteComment(
              _site.id,
              text,
              parentId: parentId,
            ).then(commentFromSiteCommentItem);
          },
          onCommentEdited: (String commentId, String body) {
            return ref.read(sitesRepositoryProvider).updateSiteComment(
              _site.id,
              commentId,
              body,
            );
          },
          onCommentDeleted: (String commentId) {
            return ref.read(sitesRepositoryProvider).deleteSiteComment(
              _site.id,
              commentId,
            );
          },
          onCommentLikeToggled: (String commentId, bool shouldLike) {
            return shouldLike
                ? ref.read(sitesRepositoryProvider).likeSiteComment(
                    _site.id,
                    commentId,
                  ).then((_) {})
                : ref.read(sitesRepositoryProvider).unlikeSiteComment(
                    _site.id,
                    commentId,
                  ).then((_) {});
          },
        );
      },
    );
  }

  Future<void> _showUpvotersSheet(BuildContext context) async {
    final int count = _site.score.clamp(0, 999);
    if (count == 0) {
      AppSnack.show(
        context,
        message: context.l10n.siteDetailNoUpvotesSnack,
        type: AppSnackType.info,
      );
      return;
    }
    AppHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const <double>[0.68, 0.95],
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusPill),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: UpvotersSheetContent(
                siteId: _site.id,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDirectionsSheet(BuildContext context) async {
    final LatLng? point = _siteCoordinates[_site.id];
    if (point == null) {
      AppSnack.show(
        context,
        message: context.l10n.siteDetailDirectionsUnavailableSnack,
        type: AppSnackType.warning,
      );
      return;
    }
    AppHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return DirectionsSheet(
          onAppleMapsTap: () {
            Navigator.of(context).pop();
            _launchMaps(dest: point, useAppleMaps: true);
          },
          onGoogleMapsTap: () {
            Navigator.of(context).pop();
            _launchMaps(dest: point, useAppleMaps: false);
          },
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Future<void> _launchMaps({required LatLng dest, required bool useAppleMaps}) async {
    final String destStr = '${dest.latitude},${dest.longitude}';
    final Uri url = useAppleMaps && DevicePlatform.isIOS
        ? Uri.parse('https://maps.apple.com/?daddr=$destStr&dirflg=d')
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$destStr',
          );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.siteDetailOpenMapsFailedSnack,
          type: AppSnackType.warning,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.siteDetailOpenMapsFailedSnack,
          type: AppSnackType.warning,
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          const AppBackButton(),
          Expanded(
            child: Center(
              child: Text(
                _site.title,
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        indicatorColor: AppColors.primaryDark,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        labelStyle: AppTypography.chipLabel.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        unselectedLabelStyle: AppTypography.chipLabel.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        tabs: <Widget>[
          Tab(text: context.l10n.siteDetailTabPollutionSite),
          Tab(text: context.l10n.siteDetailTabCleaningEvents),
        ],
      ),
    );
  }

}

