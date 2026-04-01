import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report.dart';
import 'package:chisto_mobile/features/home/data/site_issue_report_repository.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/site_detail_widgets.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/directions_sheet.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/take_action_coordinator.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/device_platform.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

class PollutionSiteDetailScreen extends StatefulWidget {
  const PollutionSiteDetailScreen({
    super.key,
    required this.site,
    this.initialTabIndex = 0,
  });

  final PollutionSite site;
  final int initialTabIndex;

  @override
  State<PollutionSiteDetailScreen> createState() =>
      _PollutionSiteDetailScreenState();
}

class _PollutionSiteDetailScreenState extends State<PollutionSiteDetailScreen> {
  late final Map<String, LatLng> _siteCoordinates;
  late final SiteIssueReportRepository _siteIssueRepo;
  late PollutionSite _site;
  bool _hasReportedIssue = false;
  bool _isSaved = false;
  bool _isUpvoteInFlight = false;
  double _upvoteScale = 1;
  List<Comment> _comments = <Comment>[];

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _siteCoordinates = <String, LatLng>{};
    if (_site.latitude != null && _site.longitude != null) {
      _siteCoordinates[_site.id] = LatLng(_site.latitude!, _site.longitude!);
    }
    _siteIssueRepo = SiteIssueReportRepository();
    _isSaved = _site.isSavedByMe;
    _comments = List<Comment>.from(_site.comments);
    _loadReportedState();
    _refreshSiteDetails();
  }

  Future<void> _loadReportedState() async {
    final bool reported = await _siteIssueRepo.hasReported(_site.id);
    if (mounted) setState(() => _hasReportedIssue = reported);
  }

  Future<void> _refreshSiteDetails() async {
    try {
      final PollutionSite? refreshed =
          await ServiceLocator.instance.sitesRepository.getSiteById(_site.id);
      if (!mounted || refreshed == null) return;
      final double resolvedDistanceKm =
          refreshed.distanceKm >= 0 ? refreshed.distanceKm : _site.distanceKm;
      setState(() {
        _site = refreshed.copyWith(distanceKm: resolvedDistanceKm);
        _isSaved = refreshed.isSavedByMe;
        _comments = List<Comment>.from(refreshed.comments);
      });
      if (refreshed.latitude != null && refreshed.longitude != null) {
        _siteCoordinates[refreshed.id] =
            LatLng(refreshed.latitude!, refreshed.longitude!);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildTabs(tabContext),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        PollutionSiteTab(
                          site: _site,
                          isReported: _hasReportedIssue,
                          onTakeAction: () => _openTakeActionDialog(tabContext),
                          onUpvoteTap: () => _onUpvoteTapped(tabContext),
                          isUpvotePending: _isUpvoteInFlight,
                          upvoteScale: _upvoteScale,
                          onScoreTap: () => _showUpvotersSheet(tabContext),
                          onCommentsTap: () => _showCommentsSheet(tabContext),
                          onParticipantsTap: () => _onParticipantsTap(tabContext),
                          onDistanceTap: () => _showDirectionsSheet(tabContext),
                          onReportedTap: () => _onReportedTap(tabContext),
                          onSaveTap: () => _onSaveTapped(tabContext),
                          onReportTap: () => _openReportIssueSheet(tabContext),
                          isSaved: _isSaved,
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
    AppHaptics.softTransition();
    final EcoEvent? createdEvent = await EventsNavigation.openCreate(
      context,
      preselectedSiteId: _site.id,
      preselectedSiteName: _site.title,
      preselectedSiteImageUrl:
          'assets/images/references/onboarding_reference.png',
      preselectedSiteDistanceKm: _site.distanceKm.toDouble(),
    );
    if (createdEvent == null || !mounted) return;
    await EventsNavigation.openDetail(context, eventId: createdEvent.id);
  }

  Future<void> _openTakeActionDialog(BuildContext context) async {
    final TakeActionType? action = await TakeActionSheet.show(context);
    if (action == null || !context.mounted) return;
    final bool shareConfirmed = await TakeActionCoordinator.execute(
      context,
      action: action,
      site: _site,
      isFromSiteDetail: true,
      onSwitchToCleaningTab: () {
        DefaultTabController.of(context).animateTo(1);
      },
    );
    if (action != TakeActionType.shareSite || !shareConfirmed) return;
    try {
      await ServiceLocator.instance.sitesRepository.shareSite(_site.id);
    } catch (_) {}
  }

  Future<void> _openReportIssueSheet(BuildContext context) async {
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
        message: context.l10n.siteDetailThankYouReportSnack,
        type: AppSnackType.success,
      );
    }
  }

  Future<void> _onSaveTapped(BuildContext context) async {
    final bool nextSaved = !_isSaved;
    setState(() => _isSaved = nextSaved);
    try {
      final snapshot = nextSaved
          ? await ServiceLocator.instance.sitesRepository.saveSite(_site.id)
          : await ServiceLocator.instance.sitesRepository.unsaveSite(_site.id);
      if (!mounted) return;
      setState(() => _isSaved = snapshot.isSavedByMe);
    } catch (_) {}
    if (!mounted || !context.mounted) return;
    AppSnack.show(
      context,
      message: nextSaved ? 'Site saved to your list.' : 'Removed from saved sites.',
      type: AppSnackType.success,
    );
  }

  Future<void> _onUpvoteTapped(BuildContext context) async {
    if (_isUpvoteInFlight) return;
    _isUpvoteInFlight = true;
    final PollutionSite previous = _site;
    final bool nextUpvoted = !_site.isUpvotedByMe;
    setState(() {
      _site = _site.copyWith(
        isUpvotedByMe: nextUpvoted,
        score: (_site.score + (nextUpvoted ? 1 : -1)).clamp(0, 9999),
      );
      _upvoteScale = 0.88;
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _upvoteScale = 1);
    });
    try {
      final snapshot = nextUpvoted
          ? await ServiceLocator.instance.sitesRepository.upvoteSite(_site.id)
          : await ServiceLocator.instance.sitesRepository.removeSiteUpvote(_site.id);
      if (!mounted) return;
      setState(() {
        _site = _site.copyWith(
          score: snapshot.upvotesCount,
          commentsCount: snapshot.commentsCount,
          shareCount: snapshot.sharesCount,
          isUpvotedByMe: snapshot.isUpvotedByMe,
          isSavedByMe: snapshot.isSavedByMe,
        );
        _isSaved = snapshot.isSavedByMe;
      });
      AppHaptics.light();
    } catch (_) {
      if (!mounted) return;
      setState(() => _site = previous);
      AppHaptics.medium();
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.siteDetailUpvoteFailedSnack,
        type: AppSnackType.warning,
      );
    } finally {
      _isUpvoteInFlight = false;
    }
  }

  Future<void> _onShareTap(BuildContext context) async {
    final bool shareConfirmed = await TakeActionCoordinator.execute(
      context,
      action: TakeActionType.shareSite,
      site: _site,
    );
    if (!shareConfirmed) return;
    try {
      await ServiceLocator.instance.sitesRepository.shareSite(_site.id);
    } catch (_) {}
  }

  Future<void> _onReportedTap(BuildContext context) async {
    final SiteReport? report = _site.firstReport;
    if (report == null) return;
    AppHaptics.tap();
    await FirstReportModal.show(context, report);
  }

  Future<void> _onParticipantsTap(BuildContext context) async {
    final List<String> coReporters = _site.coReporterNames;
    if (coReporters.isNotEmpty) {
      AppHaptics.tap();
      await CoReportersModal.show(context, coReporters);
    } else {
      await _showParticipantsSheet(context);
    }
  }

  Future<void> _showCommentsSheet(BuildContext context) async {
    AppHaptics.tap();
    Future<List<Comment>> loadComments(String sort) async {
      final result = await ServiceLocator.instance.sitesRepository.getSiteComments(
        _site.id,
        sort: sort,
      );
      return result.items.map(_commentFromSiteCommentItem).toList();
    }
    try {
      final comments = await loadComments('top');
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (_) {}
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusSheet),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: CommentsBottomSheet(
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
                onCommentSubmitted: (String text, String? parentId) {
                  return ServiceLocator.instance.sitesRepository.createSiteComment(
                    _site.id,
                    text,
                    parentId: parentId,
                  ).then(_commentFromSiteCommentItem);
                },
                onCommentEdited: (String commentId, String body) {
                  return ServiceLocator.instance.sitesRepository.updateSiteComment(
                    _site.id,
                    commentId,
                    body,
                  );
                },
                onCommentDeleted: (String commentId) {
                  return ServiceLocator.instance.sitesRepository.deleteSiteComment(
                    _site.id,
                    commentId,
                  );
                },
                onCommentLikeToggled: (String commentId, bool shouldLike) {
                  return shouldLike
                      ? ServiceLocator.instance.sitesRepository.likeSiteComment(
                          _site.id,
                          commentId,
                        ).then((_) {})
                      : ServiceLocator.instance.sitesRepository.unlikeSiteComment(
                          _site.id,
                          commentId,
                        ).then((_) {});
                },
                onSortChanged: loadComments,
              ),
            );
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
    final List<String> names = List<String>.generate(
      count,
      (int index) => 'Eco volunteer ${index + 1}',
    );
    await showModalBottomSheet<void>(
      context: context,
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
              child: _UpvotersSheetContent(
                count: count,
                names: names,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showParticipantsSheet(BuildContext context) async {
    final int count = _site.participantCount.clamp(0, 999);
    if (count == 0) {
      AppSnack.show(
        context,
        message: context.l10n.siteDetailNoVolunteersSnack,
        type: AppSnackType.info,
      );
      return;
    }
    AppHaptics.tap();
    final List<String> names = List<String>.generate(
      count,
      (int index) => 'Volunteer ${index + 1}',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusPill),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _ParticipantsSheetContent(
                count: count,
                names: names,
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
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
        tabs: const <Widget>[
          Tab(text: 'Pollution site'),
          Tab(text: 'Cleaning events'),
        ],
      ),
    );
  }

  Comment _commentFromSiteCommentItem(SiteCommentItem item) {
    final String currentUserId = ServiceLocator.instance.authState.userId ?? '';
    return Comment(
      id: item.id,
      authorName: item.authorName,
      text: item.body,
      parentId: item.parentId,
      likeCount: item.likeCount,
      isLikedByMe: item.isLikedByMe,
      isOwnedByMe: item.authorId == currentUserId,
      replies: item.replies.map(_commentFromSiteCommentItem).toList(),
    );
  }
}

class _UpvotersSheetContent extends StatelessWidget {
  const _UpvotersSheetContent({
    required this.count,
    required this.names,
    required this.scrollController,
  });

  final int count;
  final List<String> names;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$count upvote${count == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.inputFill,
                  child: Text(
                    names[index].substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                title: Text(names[index]),
              );
            },
            childCount: names.length,
          ),
        ),
      ],
    );
  }
}

class _ParticipantsSheetContent extends StatelessWidget {
  const _ParticipantsSheetContent({
    required this.count,
    required this.names,
    required this.scrollController,
  });

  final int count;
  final List<String> names;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$count volunteer${count == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.inputFill,
                  child: Text(
                    names[index].substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                title: Text(names[index]),
              );
            },
            childCount: names.length,
          ),
        ),
      ],
    );
  }
}
