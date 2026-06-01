part of 'package:feature_home/src/presentation/screens/pollution_site_detail_screen.dart';

/// Sheet launchers and engagement actions for [PollutionSiteDetailScreen].
extension SiteDetailSheetsLauncher on _PollutionSiteDetailScreenState {
  Future<void> _createEvent() async {
    try {
      final EcoEvent? createdEvent = await EventsNavigation.openCreate(
        context,
        auth: ref.read(authStateProvider),
        preselectedSiteId: _site.id,
        preselectedSiteName: _site.title,
        preselectedSiteImageUrl:
            _site.primaryImageUrl != null &&
                _site.primaryImageUrl!.trim().isNotEmpty
            ? _site.primaryImageUrl!.trim()
            : 'assets/images/references/onboarding_reference.png',
        preselectedSiteDistanceKm: _site.distanceKm,
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
    final TakeActionCoordinatorOutcome outcome =
        await TakeActionCoordinator.execute(
          context,
          ref,
          action: action,
          site: _site,
          isFromSiteDetail: true,
          onSwitchToCleaningTab: () {
            DefaultTabController.of(context).animateTo(1);
          },
        );
    if (!mounted) return;
    if (action == TakeActionType.shareSite &&
        outcome is TakeActionCoordinatorShareOutcome) {
      _applyShareCoordinatorOutcome(outcome.share);
    }
  }

  Future<void> _openReportIssueSheet(BuildContext context) async {
    final l10n = context.l10n;
    await ref
        .read(sitesRepositoryProvider)
        .trackFeedEvent(_site.id, eventType: 'cta_report_issue_opened');
    if (!context.mounted) return;
    final bool? reported = await ReportIssueSheet.show(
      context,
      site: _site,
      repository: _siteIssueRepo,
    );
    if (!context.mounted) return;
    if (reported ?? false) {
      rebuildState(() => _hasReportedIssue = true);
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
      ref
          .read(feedSitesNotifierProvider.notifier)
          .patchSiteSaved(
            _site.id,
            isSavedByMe: ref
                .read(siteEngagementNotifierProvider(_site.id))
                .isSaved,
          );
    }
    if (outcome.isSuccess) {
      final bool nowSaved = ref
          .read(siteEngagementNotifierProvider(_site.id))
          .isSaved;
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
    final SiteEngagementOutcome outcome = await ref
        .read(siteEngagementNotifierProvider(_site.id).notifier)
        .toggleUpvote();
    if (!mounted) return;
    _applyEngagementToSite();
    if (!context.mounted) return;
    if (outcome.isSuccess) {
      // Subtle second pulse only when ending in upvoted state (add), not on remove — avoids double-buzz noise.
      if (ref.read(siteEngagementNotifierProvider(_site.id)).isUpvoted) {}
      return;
    }
    if (outcome.kind == SiteEngagementOutcomeKind.failure) {}
    showSiteEngagementOutcomeSnack(
      context,
      outcome,
      genericFailureMessage: context.l10n.siteDetailUpvoteFailedSnack,
    );
  }

  Future<void> _onShareTap(BuildContext context) async {
    final TakeActionCoordinatorOutcome outcome =
        await TakeActionCoordinator.execute(
          context,
          ref,
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
        ref
            .read(siteEngagementNotifierProvider(_site.id).notifier)
            .setShareCount(snapshot.sharesCount);
        _applyEngagementToSite();
      case SiteShareCancelled():
      case SiteShareTrackFailed():
        break;
    }
  }

  Future<void> _onReportedTap(BuildContext context) async {
    final SiteReport? report = _site.displayFirstReport;
    if (report == null) return;
    await FirstReportModal.show(context, report);
  }

  Future<void> _onParticipantsTap(BuildContext context) async {
    final List<CoReporterProfile> coReporters = _site.displayCoReporterProfiles;
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

  Future<void> _showCommentsSheet(
    BuildContext context, {
    String? highlightCommentId,
    String? highlightActorUserId,
  }) async {
    final l10n = context.l10n;
    final String currentUserId = ref.read(authStateProvider).userId ?? '';
    Future<List<Comment>> loadComments(String sort) async {
      final result = await ref
          .read(sitesRepositoryProvider)
          .getSiteComments(_site.id, sort: sort);
      return result.items
          .map(
            (SiteCommentItem item) =>
                commentFromSiteCommentItem(currentUserId, item),
          )
          .toList();
    }

    try {
      final comments = await loadComments('top');
      if (mounted) {
        rebuildState(() {
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
          highlightCommentId: highlightCommentId,
          highlightActorUserId: highlightActorUserId,
          onCommentsCountChanged: (int count) {
            if (!mounted) return;
            rebuildState(() {
              _site = _site.copyWith(commentsCount: count);
            });
          },
          onCommentsChanged: (comments) {
            if (!mounted) return;
            rebuildState(() => _comments = comments);
          },
          onLoadMoreDirectReplies:
              (String parentId, int page, String sort) async {
                final SiteCommentsResult result = await ref
                    .read(sitesRepositoryProvider)
                    .getSiteComments(
                      _site.id,
                      parentId: parentId,
                      page: page,
                      limit: 20,
                      sort: sort,
                    );
                return result.items
                    .map(
                      (SiteCommentItem item) =>
                          commentFromSiteCommentItem(currentUserId, item),
                    )
                    .toList();
              },
          onCommentSubmitted: (String text, String? parentId) {
            return ref
                .read(sitesRepositoryProvider)
                .createSiteComment(_site.id, text, parentId: parentId)
                .then(
                  (SiteCommentItem item) =>
                      commentFromSiteCommentItem(currentUserId, item),
                );
          },
          onCommentEdited: (String commentId, String body) {
            return ref
                .read(sitesRepositoryProvider)
                .updateSiteComment(_site.id, commentId, body);
          },
          onCommentDeleted: (String commentId) {
            return ref
                .read(sitesRepositoryProvider)
                .deleteSiteComment(_site.id, commentId);
          },
          onCommentLikeToggled: (String commentId, bool shouldLike) {
            return shouldLike
                ? ref
                      .read(sitesRepositoryProvider)
                      .likeSiteComment(_site.id, commentId)
                      .then((_) {})
                : ref
                      .read(sitesRepositoryProvider)
                      .unlikeSiteComment(_site.id, commentId)
                      .then((_) {});
          },
        );
      },
    );
  }

  Future<void> _showUpvotersSheet(
    BuildContext context, {
    String? highlightUserId,
  }) async {
    if (!context.mounted) return;
    await openPollutionSiteCardUpvotersSheet(
      context: context,
      ref: ref,
      siteId: _site.id,
      highlightUserId: highlightUserId,
    );
  }

  Future<void> _showDirectionsSheet(BuildContext context) async {
    final String directionsUnavailableSnack =
        context.l10n.siteDetailDirectionsUnavailableSnack;
    final LatLng? point = _siteCoordinates[_site.id];
    if (point == null) {
      AppSnack.show(
        context,
        message: directionsUnavailableSnack,
        type: AppSnackType.warning,
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext sheetContext) {
        return DirectionsSheet(
          onAppleMapsTap: () {
            Navigator.of(sheetContext).pop();
            _launchMaps(dest: point, useAppleMaps: true);
          },
          onGoogleMapsTap: () {
            Navigator.of(sheetContext).pop();
            _launchMaps(dest: point, useAppleMaps: false);
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  Future<void> _launchMaps({
    required LatLng dest,
    required bool useAppleMaps,
  }) async {
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
}
