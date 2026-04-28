import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/feed_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_engagement_outcome_snack.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/site_share_result.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/take_action_coordinator.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/feed_feedback_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_card_engagement_bar.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_card_image_carousel.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_image_resolver.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/pollution_site_card_analytics.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/pollution_site_card_sheets.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_card_widgets.dart';
import 'package:chisto_mobile/core/cache/site_image_prefetch_queue.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

class PollutionSiteCard extends ConsumerStatefulWidget {
  const PollutionSiteCard({
    super.key,
    required this.site,
    this.feedSessionId,
    this.onHidden,
  });

  final PollutionSite site;
  final String? feedSessionId;
  final ValueChanged<String>? onHidden;

  @override
  ConsumerState<PollutionSiteCard> createState() => _PollutionSiteCardState();
}

class _PollutionSiteCardState extends ConsumerState<PollutionSiteCard>
    with AutomaticKeepAliveClientMixin {
  late List<Comment> _sessionComments;
  double _saveIconScale = 1.0;
  bool _didPrefetchImages = false;
  bool _isCardVisible = true;
  bool _didHydrateEngagement = false;
  bool _isShareInFlight = false;
  final DateTime _openedAt = DateTime.now();
  bool _impressionTracked = false;
  Timer? _impressionTimer;

  static const double _cardRadius = AppSpacing.radiusXl;
  PollutionSite get site => widget.site;

  void _scheduleEngagementHydrate(PollutionSite s) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(siteEngagementNotifierProvider(s.id).notifier).hydrate(s);
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sessionComments = List<Comment>.from(site.comments);
  }

  @override
  void dispose() {
    _impressionTimer?.cancel();
    final int dwellSeconds = DateTime.now().difference(_openedAt).inSeconds;
    if (_impressionTracked && dwellSeconds >= 2) {
      trackPollutionFeedCardEvent(
        site.id,
        eventType: PollutionFeedCardEventType.dwellBucket,
        sessionId: widget.feedSessionId,
        metadata: <String, dynamic>{
          'bucket': feedCardDwellBucketForSeconds(dwellSeconds),
        },
      );
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PollutionSiteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool changedSite = oldWidget.site.id != widget.site.id;
    final bool changedEngagement =
        oldWidget.site.score != widget.site.score ||
        oldWidget.site.commentCount != widget.site.commentCount ||
        oldWidget.site.shareCount != widget.site.shareCount ||
        oldWidget.site.isUpvotedByMe != widget.site.isUpvotedByMe ||
        oldWidget.site.isSavedByMe != widget.site.isSavedByMe;
    if (changedSite || changedEngagement) {
      _scheduleEngagementHydrate(site);
      if (changedSite ||
          oldWidget.site.comments.length != site.comments.length) {
        _sessionComments = List<Comment>.from(site.comments);
      }
      if (changedSite) {
        _impressionTracked = false;
        _impressionTimer?.cancel();
        _impressionTimer = null;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didHydrateEngagement) {
      _didHydrateEngagement = true;
      _scheduleEngagementHydrate(site);
    }
    if (_didPrefetchImages) return;
    _didPrefetchImages = true;
    final List<ImageProvider> images = siteGalleryImageProviders(site);
    SiteImagePrefetchQueue.instance.prefetchList(
      context,
      images,
      maxItems: 3,
      shouldPrefetch: () => mounted,
    );
  }

  Future<void> _onUpvoteTap() async {
    if (!mounted) return;
    AppHaptics.tap(context);
    final SiteEngagementOutcome outcome = await ref
        .read(siteEngagementNotifierProvider(site.id).notifier)
        .toggleUpvote();
    if (!mounted) return;
    if (outcome.isSuccess) {
      if (ref.read(siteEngagementNotifierProvider(site.id)).isUpvoted) {
        AppHaptics.light(context);
      }
      trackPollutionFeedCardEvent(
        site.id,
        eventType: PollutionFeedCardEventType.like,
        sessionId: widget.feedSessionId,
      );
      return;
    }
    showSiteEngagementOutcomeSnack(
      context,
      outcome,
      genericFailureMessage: context.l10n.siteCardUpvoteFailedSnack,
    );
    if (outcome.kind == SiteEngagementOutcomeKind.failure) {
      AppHaptics.medium();
    }
  }

  Future<void> _toggleSave() async {
    AppHaptics.light(context);
    setState(() => _saveIconScale = 0.9);

    Future<void>.delayed(AppMotion.xFast, () {
      if (!mounted) return;
      setState(() => _saveIconScale = 1.0);
    });

    final SiteEngagementOutcome outcome = await ref
        .read(siteEngagementNotifierProvider(site.id).notifier)
        .toggleSave();
    if (!mounted) return;
    final bool shouldSyncFeedList = outcome.isSuccess ||
        outcome.kind == SiteEngagementOutcomeKind.queuedOffline;
    if (shouldSyncFeedList) {
      final bool savedFlag =
          ref.read(siteEngagementNotifierProvider(site.id)).isSaved;
      ref.read(feedSitesNotifierProvider.notifier).patchSiteSaved(site.id, savedFlag);
    }
    if (outcome.isSuccess) {
      final bool nowSaved = ref.read(siteEngagementNotifierProvider(site.id)).isSaved;
      AppHaptics.success(context);
      AppSnack.show(
        context,
        message: nowSaved
            ? context.l10n.siteCardSaveUpdatesOnSnack
            : context.l10n.siteCardSaveRemovedSnack,
        type: nowSaved ? AppSnackType.success : AppSnackType.info,
        duration: const Duration(milliseconds: 1200),
      );
      trackPollutionFeedCardEvent(
        site.id,
        eventType: PollutionFeedCardEventType.save,
        sessionId: widget.feedSessionId,
        metadata: <String, dynamic>{'saved': nowSaved},
      );
      return;
    }
    showSiteEngagementOutcomeSnack(
      context,
      outcome,
      genericFailureMessage: context.l10n.siteCardSavedFailedSnack,
    );
  }

  Widget _buildAnimatedCount(int value, TextStyle style) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text('$value', key: ValueKey<int>(value), style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ({
      bool isUpvoted,
      int upvoteCount,
      int commentCount,
      int shareCount,
      bool isSaved,
      bool isUpvoteInFlight,
      bool isSaveInFlight,
    }) eng = ref.watch(
      siteEngagementNotifierProvider(site.id).select(
        (SiteEngagementState s) => (
          isUpvoted: s.isUpvoted,
          upvoteCount: s.upvoteCount,
          commentCount: s.commentCount,
          shareCount: s.shareCount,
          isSaved: s.isSaved,
          isUpvoteInFlight: s.isUpvoteInFlight,
          isSaveInFlight: s.isSaveInFlight,
        ),
      ),
    );
    return VisibilityDetector(
      key: ValueKey<String>('feed-card-${site.id}'),
      onVisibilityChanged: (VisibilityInfo info) {
        _isCardVisible = info.visibleFraction > 0.14;
        if (_impressionTracked) return;
        if (info.visibleFraction < 0.5) {
          _impressionTimer?.cancel();
          _impressionTimer = null;
          return;
        }
        _impressionTimer ??= Timer(const Duration(milliseconds: 500), () {
          if (!mounted || _impressionTracked) return;
          trackPollutionFeedCardEvent(
            site.id,
            eventType: PollutionFeedCardEventType.impression,
            sessionId: widget.feedSessionId,
          );
          _impressionTracked = true;
          _impressionTimer = null;
        });
      },
      child: Semantics(
        button: false,
        label: context.l10n.siteCardPollutionSiteSemantic(site.title),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: AppSpacing.md,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: AppSpacing.lg,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () => _openDetails(context),
                splashColor: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.black.withValues(alpha: 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SiteCardImageCarousel(
                      siteId: site.id,
                      siteTitle: site.title,
                      images: siteGalleryImageProviders(site),
                      statusColor: site.statusColor,
                      statusLine: site.distanceKm >= 0
                          ? '${site.statusLabel} • ${_formatDistance(context, site.distanceKm)}'
                          : site.statusLabel,
                      onMenuTap: _openFeedbackSheet,
                      onPageIndexChanged: (int index) {
                        _prefetchAround(index, siteGalleryImageProviders(site));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SiteCardEngagementBar(
                            siteTitle: site.title,
                            isUpvoted: eng.isUpvoted,
                            upvoteCount: eng.upvoteCount,
                            commentCount: eng.commentCount,
                            shareCount: eng.shareCount,
                            isSaved: eng.isSaved,
                            saveIconScale: _saveIconScale,
                            isUpvoteInFlight: eng.isUpvoteInFlight,
                            isSaveInFlight: eng.isSaveInFlight,
                            isShareInFlight: _isShareInFlight,
                            onUpvoteTap: _onUpvoteTap,
                            onUpvoteCountTap: () => _showUpvotersSheet(context),
                            onCommentsTap: _openCommentsSheet,
                            onShareTap: _openShareSheet,
                            onSaveTap: _toggleSave,
                            buildAnimatedCount: _buildAnimatedCount,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SiteCardBody(
                            site: site,
                            onTakeAction: () {
                              _openTakeActionSheet();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _prefetchAround(int index, List<ImageProvider> images) {
    SiteImagePrefetchQueue.instance.prefetchAround(
      context,
      images,
      index,
      shouldPrefetch: () => mounted && _isCardVisible,
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    AppHaptics.softTransition();
    trackPollutionFeedCardEvent(
      site.id,
      eventType: PollutionFeedCardEventType.detailOpen,
      sessionId: widget.feedSessionId,
    );
    SiteImagePrefetchQueue.instance.prefetchList(
      context,
      siteGalleryImageProviders(site),
      maxItems: 3,
      shouldPrefetch: () => mounted,
    );
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) {
      await router.push('/feed/${site.id}', extra: site);
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PollutionSiteDetailScreen(site: site),
        ),
      );
    }
    if (!mounted) return;
    try {
      final refreshed = await ref.read(sitesRepositoryProvider).getSiteById(site.id);
      if (!mounted || refreshed == null) return;
      ref.read(siteEngagementNotifierProvider(site.id).notifier).hydrate(refreshed);
    } catch (_) {
      // Detail rehydrate is best-effort; leaving current optimistic state is acceptable.
    }
  }

  Future<void> _openCommentsSheet() async {
    await openPollutionSiteCardCommentsSheet(
      context: context,
      ref: ref,
      site: site,
      initialSessionComments: _sessionComments,
      onSessionCommentsReplaced: (List<Comment> next) {
        if (!mounted) return;
        setState(() => _sessionComments = next);
      },
      onSessionCommentsChanged: (List<Comment> next) {
        if (!mounted) return;
        setState(() => _sessionComments = next);
      },
      feedSessionId: widget.feedSessionId,
    );
  }

  Future<void> _openTakeActionSheet() async {
    if (_isShareInFlight) return;
    trackPollutionFeedCardEvent(
      site.id,
      eventType: PollutionFeedCardEventType.ctaOpened,
      sessionId: widget.feedSessionId,
    );
    final TakeActionType? action = await TakeActionSheet.show(context);
    if (action == null || !mounted) return;
    final PollutionFeedCardEventType actionEvent = switch (action) {
      TakeActionType.createEcoAction => PollutionFeedCardEventType.ctaCreateStarted,
      TakeActionType.joinAction => PollutionFeedCardEventType.ctaJoinStarted,
      TakeActionType.shareSite => PollutionFeedCardEventType.ctaShareStarted,
      TakeActionType.donateContribute => PollutionFeedCardEventType.ctaDonateStarted,
    };
    trackPollutionFeedCardEvent(
      site.id,
      eventType: actionEvent,
      sessionId: widget.feedSessionId,
    );
    _isShareInFlight = action == TakeActionType.shareSite;
    if (_isShareInFlight) {
      setState(() {});
    }
    try {
      final TakeActionCoordinatorOutcome outcome = await TakeActionCoordinator.execute(
        context,
        action: action,
        site: site,
        isFromSiteDetail: false,
      );
      if (!mounted) return;
      if (action == TakeActionType.shareSite && outcome is TakeActionCoordinatorShareOutcome) {
        _applyShareOutcome(outcome.share);
      } else if (action == TakeActionType.createEcoAction ||
          action == TakeActionType.joinAction) {
        final PollutionFeedCardEventType successEvent =
            action == TakeActionType.createEcoAction
                ? PollutionFeedCardEventType.ctaCreateFinished
                : PollutionFeedCardEventType.ctaJoinFinished;
        trackPollutionFeedCardEvent(
          site.id,
          eventType: successEvent,
          sessionId: widget.feedSessionId,
        );
      }
    } finally {
      if (_isShareInFlight) {
        _isShareInFlight = false;
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _openShareSheet() async {
    if (_isShareInFlight) return;
    _isShareInFlight = true;
    setState(() {});
    try {
      final TakeActionCoordinatorOutcome outcome = await TakeActionCoordinator.execute(
        context,
        action: TakeActionType.shareSite,
        site: site,
        isFromSiteDetail: false,
      );
      if (!mounted) return;
      if (outcome is TakeActionCoordinatorShareOutcome) {
        _applyShareOutcome(outcome.share);
      }
    } finally {
      _isShareInFlight = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _applyShareOutcome(SiteShareResult share) {
    switch (share) {
      case SiteShareSuccess(:final EngagementSnapshot snapshot):
        ref.read(siteEngagementNotifierProvider(site.id).notifier).setShareCount(snapshot.sharesCount);
        trackPollutionFeedCardEvent(
          site.id,
          eventType: PollutionFeedCardEventType.share,
          sessionId: widget.feedSessionId,
        );
      case SiteShareCancelled():
        trackPollutionFeedCardEvent(
          site.id,
          eventType: PollutionFeedCardEventType.ctaShareCancelled,
          sessionId: widget.feedSessionId,
        );
      case SiteShareTrackFailed():
        trackPollutionFeedCardEvent(
          site.id,
          eventType: PollutionFeedCardEventType.ctaShareTrackFailed,
          sessionId: widget.feedSessionId,
        );
        break;
    }
  }

  Future<void> _showUpvotersSheet(BuildContext context) async {
    await openPollutionSiteCardUpvotersSheet(
      context: context,
      ref: ref,
      siteId: site.id,
    );
  }

  String _formatDistance(BuildContext context, double km) {
    final AppLocalizations l10n = context.l10n;
    if (km < 1) {
      final int meters = (km * 1000).round().clamp(1, 999);
      return l10n.siteCardDistanceMeters(meters);
    }
    if (km < 10) {
      return l10n.siteCardDistanceKmShort(km.toStringAsFixed(1));
    }
    return l10n.siteCardDistanceKmWhole(km.toStringAsFixed(0));
  }

  Future<void> _onFeedbackSelected(FeedCardFeedbackAction action) async {
    final String feedbackType = switch (action) {
      FeedCardFeedbackAction.notRelevant => 'not_relevant',
      FeedCardFeedbackAction.showLess => 'show_more',
      FeedCardFeedbackAction.duplicate => 'duplicate',
      FeedCardFeedbackAction.misleading => 'misleading',
      FeedCardFeedbackAction.hide => 'not_relevant',
    };
    try {
      await ref.read(sitesRepositoryProvider).submitFeedFeedback(
        site.id,
        feedbackType: feedbackType,
        sessionId: widget.feedSessionId,
        metadata: <String, dynamic>{
          'source': 'feed_card_menu',
          'action': action.name,
        },
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: action == FeedCardFeedbackAction.hide
            ? context.l10n.siteCardFeedbackPostHiddenSnack
            : context.l10n.siteCardFeedbackThanksSnack,
        type: AppSnackType.info,
      );
      if (action == FeedCardFeedbackAction.hide) {
        widget.onHidden?.call(site.id);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.siteCardFeedbackSubmitFailedSnack,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _openFeedbackSheet() async {
    AppHaptics.tap();
    final FeedCardFeedbackAction? action =
        await showModalBottomSheet<FeedCardFeedbackAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => const FeedFeedbackSheet(),
    );
    if (action == null) return;
    await _onFeedbackSelected(action);
  }
}
