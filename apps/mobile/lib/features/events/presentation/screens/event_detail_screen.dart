import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/events/presentation/utils/organizer_end_soon_local_controller.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/extend_event_end_sheet.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/field_mode_queue.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_export.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_scroll_interaction.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/after_photos_gallery.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/detail_content.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/feedback_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_detail_cta_presentation.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/hero_image_bar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_layout.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_not_found_view.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/reminder_picker_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/screens/edit_event_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/sticky_bottom_cta.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail_skeleton.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.enableThumbnailHero = false,
    @visibleForTesting this.eventsRepository,
  });

  final String eventId;

  /// When false, the cover is not wrapped in [Hero] (used when replacing detail for
  /// another event to avoid `_HeroFlight.divert` with mismatched tags).
  final bool enableThumbnailHero;

  /// Pinned repository for widget tests; production uses [EventsRepositoryRegistry].
  @visibleForTesting
  final EventsRepository? eventsRepository;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with WidgetsBindingObserver {
  EventsRepository get _eventsStore =>
      widget.eventsRepository ?? EventsRepositoryRegistry.instance;
  final EventFeedbackLocalCache _feedbackCache =
      const EventFeedbackLocalCache();
  static const Duration _detailResumeRefreshTtlDefault = Duration(seconds: 45);
  static const Duration _detailResumeRefreshTtlHot = Duration(seconds: 15);

  Duration _detailResumeRefreshTtl(EcoEvent event) {
    if (event.isCheckInOpen || event.status == EcoEventStatus.inProgress) {
      return _detailResumeRefreshTtlHot;
    }
    return _detailResumeRefreshTtlDefault;
  }

  EventFeedbackSnapshot? _feedbackSnapshot;
  bool _detailPrefetchDone = false;
  bool _detailMissing = false;
  DateTime? _lastDetailRefreshAt;
  Future<void>? _detailPrefetchInFlight;
  bool _ctaMutationBusy = false;
  int _chatUnreadCount = 0;
  final OrganizerEndSoonLocalController _organizerEndSoonLocal =
      OrganizerEndSoonLocalController();
  Timer? _joinWindowTicker;
  final ScrollController _detailScrollController = ScrollController();

  /// True once scroll offset passes the fully-collapsed hero height (body
  /// scrolling under the pinned toolbar). Feeds [HeroImageBar.innerBoxIsScrolled].
  bool _heroCollapsedEnoughForBodyScroll = false;

  /// True when a forced refresh failed while we still show a cached [EcoEvent].
  bool _localDetailRefreshFailed = false;

  bool get _showStaleDetailBanner =>
      _eventsStore.isShowingStaleCachedEvents || _localDetailRefreshFailed;

  static const double _heroFullyCollapsedScrollOffset =
      kEventDetailHeroExpandedHeight - kToolbarHeight;

  void _onDetailScroll() {
    if (!mounted || !_detailScrollController.hasClients) {
      return;
    }
    final bool next =
        _detailScrollController.offset > _heroFullyCollapsedScrollOffset;
    if (next != _heroCollapsedEnoughForBodyScroll) {
      setState(() => _heroCollapsedEnoughForBodyScroll = next);
    }
  }

  bool _canOpenEventChat(EcoEvent e) =>
      (e.isJoined || e.isOrganizer) && e.status != EcoEventStatus.cancelled;

  Future<void> _refreshChatUnread(EcoEvent event) async {
    if (!_canOpenEventChat(event)) {
      if (mounted) {
        setState(() => _chatUnreadCount = 0);
      }
      return;
    }
    try {
      final int c = await ServiceLocator.instance.eventChatRepository
          .fetchUnreadCount(widget.eventId);
      if (mounted) {
        setState(() => _chatUnreadCount = c);
      }
    } on Object catch (_) {
      logEventsDiagnostic('detail_chat_unread_fetch_failed');
    }
  }

  void _openEventChat(EcoEvent event) {
    final Completer<void> readSync = Completer<void>();
    Navigator.of(context)
        .pushNamed(
          AppRoutes.eventChat,
          arguments: EventChatRouteArguments(
            eventId: event.id,
            eventTitle: event.title,
            isOrganizer: event.isOrganizer,
            readSyncCompleter: readSync,
          ),
        )
        .then((_) async {
          if (!mounted) {
            return;
          }
          try {
            await readSync.future.timeout(const Duration(seconds: 8));
          } on Object catch (_) {
            logEventsDiagnostic('detail_chat_read_sync_timeout');
          }
          if (mounted) {
            unawaited(_refreshChatUnread(event));
          }
        });
  }

  Future<void> _withCtaMutationBusy(Future<void> Function() action) async {
    if (_ctaMutationBusy || !mounted) {
      return;
    }
    setState(() => _ctaMutationBusy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _ctaMutationBusy = false);
      }
    }
  }

  double _estimatedCtaReserveHeight(BuildContext context, EcoEvent event) {
    final double bottomSafe = MediaQuery.paddingOf(context).bottom;
    final EventDetailCtaPresentation p = resolveEventDetailCtaPresentation(
      event: event,
      l10n: context.l10n,
    );
    return p.showsSecondaryRow
        ? kEventDetailMinimumCtaReserveHeight(bottomSafe)
        : kEventDetailMinimumCtaReserveHeightSingle(bottomSafe);
  }

  double _scrollBottomInset(BuildContext context, EcoEvent event) {
    return _estimatedCtaReserveHeight(context, event) + AppSpacing.lg;
  }

  Future<void> _retryDetailRefresh() async {
    AppHaptics.tap();
    try {
      final bool fetched = await _eventsStore.prefetchEvent(
        widget.eventId,
        force: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (fetched) {
          _localDetailRefreshFailed = false;
          _lastDetailRefreshAt = DateTime.now();
        }
      });
    } on Object {
      if (mounted) {
        setState(() => _localDetailRefreshFailed = true);
      }
    }
  }

  void _ensureJoinWindowTicker() {
    if (!mounted) {
      return;
    }
    final EcoEvent? e = _eventsStore.findById(widget.eventId);
    final bool needTicker = e != null && e.shouldTickVolunteerJoinNearDeadline;
    if (!needTicker) {
      _joinWindowTicker?.cancel();
      _joinWindowTicker = null;
      return;
    }
    if (_joinWindowTicker != null) {
      return;
    }
    _joinWindowTicker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) {
        return;
      }
      final EcoEvent? cur = _eventsStore.findById(widget.eventId);
      final bool stillNeed =
          cur != null && cur.shouldTickVolunteerJoinNearDeadline;
      if (!stillNeed) {
        _joinWindowTicker?.cancel();
        _joinWindowTicker = null;
        return;
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(EventDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      if (_detailScrollController.hasClients) {
        _detailScrollController.jumpTo(0);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _detailScrollController.hasClients) {
            _detailScrollController.jumpTo(0);
          }
        });
      }
      if (_heroCollapsedEnoughForBodyScroll) {
        setState(() => _heroCollapsedEnoughForBodyScroll = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventsStore.loadInitialIfNeeded();
    _eventsStore.addListener(_onStoreChanged);
    _loadFeedback();
    unawaited(_prefetchDetailDeduped());
    _detailScrollController.addListener(_onDetailScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureJoinWindowTicker();
        _onDetailScroll();
      }
    });
  }

  @override
  void dispose() {
    _detailScrollController.removeListener(_onDetailScroll);
    _detailScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _eventsStore.removeListener(_onStoreChanged);
    if (ServiceLocator.instance.isInitialized) {
      unawaited(
        _organizerEndSoonLocal.dispose(
          ServiceLocator.instance.pushNotificationService,
        ),
      );
    }
    _joinWindowTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDetailIfStale());
      _ensureJoinWindowTicker();
    }
  }

  void _onStoreChanged() {
    if (!mounted) {
      return;
    }
    void applyUpdate() {
      if (!mounted) {
        return;
      }
      setState(() {});
      _ensureJoinWindowTicker();
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
      return;
    }
    applyUpdate();
  }

  Future<void> _loadFeedback() async {
    final EventFeedbackSnapshot? snapshot = await _feedbackCache.read(
      widget.eventId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _feedbackSnapshot = snapshot;
    });
  }

  /// Dedupes overlapping open/resume prefetch calls so only one [prefetchEvent] runs.
  Future<void> _prefetchDetailDeduped() {
    if (_detailPrefetchInFlight != null) {
      return _detailPrefetchInFlight!;
    }
    final Future<void> started = _prefetchDetail();
    _detailPrefetchInFlight = started.whenComplete(() {
      _detailPrefetchInFlight = null;
    });
    return _detailPrefetchInFlight!;
  }

  Future<void> _prefetchDetail() async {
    bool fetched = false;
    bool refreshFailedWithCache = false;
    final bool hadCachedEvent = _eventsStore.findById(widget.eventId) != null;
    try {
      // When already bootstrapped, skip awaiting [EventsRepository.ready]: in widget
      // tests the completed hydration completer can otherwise stall the async gap
      // until extra pumps, leaving the skeleton visible indefinitely.
      if (!_eventsStore.isReady) {
        await _eventsStore.ready;
      }
      try {
        fetched = await _eventsStore.prefetchEvent(
          widget.eventId,
          force: hadCachedEvent,
        );
        if (fetched) {
          _lastDetailRefreshAt = DateTime.now();
        } else if (hadCachedEvent &&
            _eventsStore.findById(widget.eventId) != null) {
          // Forced refresh did not update (e.g. simulated network failure) but
          // list cache still holds a row — surface stale state.
          refreshFailedWithCache = true;
        }
      } on Object {
        fetched = false;
        if (_eventsStore.findById(widget.eventId) != null) {
          refreshFailedWithCache = true;
        }
      }
    } finally {
      if (mounted) {
        final EcoEvent? resolved = _eventsStore.findById(widget.eventId);
        setState(() {
          _detailPrefetchDone = true;
          _detailMissing = resolved == null && !fetched;
          if (refreshFailedWithCache) {
            _localDetailRefreshFailed = true;
          }
          if (fetched) {
            _localDetailRefreshFailed = false;
          }
        });
        if (resolved != null) {
          unawaited(_refreshChatUnread(resolved));
        }
      }
    }
  }

  Future<void> _handlePullToRefresh() async {
    eventsPullRefreshHaptic(context);
    try {
      final bool fetched = await _eventsStore.prefetchEvent(
        widget.eventId,
        force: true,
      );
      if (!mounted) {
        return;
      }
      if (fetched) {
        _lastDetailRefreshAt = DateTime.now();
        setState(() => _localDetailRefreshFailed = false);
        final EcoEvent? refreshed = _eventsStore.findById(widget.eventId);
        if (refreshed != null) {
          unawaited(_refreshChatUnread(refreshed));
        }
      } else if (_eventsStore.findById(widget.eventId) != null) {
        setState(() => _localDetailRefreshFailed = true);
      }
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      logEventsDiagnostic('events_detail_refresh_failed');
      if (_eventsStore.findById(widget.eventId) != null) {
        setState(() => _localDetailRefreshFailed = true);
      }
      AppSnack.show(
        context,
        message: localizedAppErrorMessage(context.l10n, e),
        type: AppSnackType.warning,
      );
    } on Object {
      if (!mounted) {
        return;
      }
      logEventsDiagnostic('events_detail_refresh_failed');
      if (_eventsStore.findById(widget.eventId) != null) {
        setState(() => _localDetailRefreshFailed = true);
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsDetailRefreshFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _refreshDetailIfStale() async {
    final EcoEvent? event = _eventsStore.findById(widget.eventId);
    if (event == null) {
      return;
    }
    final DateTime? lastRefresh = _lastDetailRefreshAt;
    if (lastRefresh != null &&
        DateTime.now().difference(lastRefresh) <
            _detailResumeRefreshTtl(event)) {
      return;
    }
    try {
      final bool fetched = await _eventsStore.prefetchEvent(
        widget.eventId,
        force: true,
      );
      if (!mounted) {
        return;
      }
      if (fetched) {
        _lastDetailRefreshAt = DateTime.now();
        setState(() => _localDetailRefreshFailed = false);
      }
    } on Object {
      if (mounted && _eventsStore.findById(widget.eventId) != null) {
        setState(() => _localDetailRefreshFailed = true);
      }
    }
  }

  Future<void> _editFeedback(EcoEvent event) async {
    final EventFeedbackSnapshot? current = _feedbackSnapshot;
    final EventFeedbackSnapshot? updated = await _showFeedbackSheet(
      event,
      current,
    );
    if (!mounted || updated == null) {
      return;
    }
    await _feedbackCache.write(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _feedbackSnapshot = updated;
    });
    AppSnack.show(
      context,
      message: current == null
          ? context.l10n.eventsImpactSummarySaved
          : context.l10n.eventsImpactSummaryUpdated,
      type: AppSnackType.success,
    );
  }

  Future<void> _saveBagsCollected(EcoEvent event, int bagsCollected) async {
    final int clamped = bagsCollected.clamp(0, 9999);
    final EventFeedbackSnapshot? cur = _feedbackSnapshot;
    final EventFeedbackSnapshot next = EventFeedbackSnapshot(
      eventId: event.id,
      rating: cur?.rating ?? 5,
      bagsCollected: clamped,
      volunteerHours: cur?.volunteerHours ?? 2.0,
      notes: cur?.notes ?? '',
      createdAt: cur?.createdAt ?? DateTime.now(),
    );
    await _feedbackCache.write(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _feedbackSnapshot = next;
    });
    AppHaptics.success();
    AppSnack.show(
      context,
      message: context.l10n.eventsCompletedBagsSaved,
      type: AppSnackType.success,
    );
    unawaited(_pushLiveImpactBags(event.id, clamped));
  }

  Future<void> _pushLiveImpactBags(String eventId, int bags) async {
    try {
      final ApiResponse res = await ServiceLocator.instance.apiClient.patch(
        '/events/$eventId/live-impact',
        body: <String, dynamic>{'reportedBagsCollected': bags},
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        await FieldModeQueue.instance.enqueueLiveImpactBags(
          eventId: eventId,
          reportedBagsCollected: bags,
        );
        return;
      }
      await EventsRepositoryRegistry.instance.prefetchEvent(eventId, force: true);
    } on Object {
      await FieldModeQueue.instance.enqueueLiveImpactBags(
        eventId: eventId,
        reportedBagsCollected: bags,
      );
    }
  }

  Future<EventFeedbackSnapshot?> _showFeedbackSheet(
    EcoEvent event,
    EventFeedbackSnapshot? current,
  ) async {
    return showEventsSurfaceModal<EventFeedbackSnapshot>(
      context: context,
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
          ),
          child: ReportSheetScaffold(
            title: sheetCtx.l10n.eventsFeedbackSheetTitle,
            subtitle: event.title,
            maxHeightFactor: 0.92,
            child: FeedbackSheetContent(event: event, current: current),
          ),
        );
      },
    );
  }

  Future<void> _handleStartEvent(EcoEvent event) async {
    if (event.isBeforeScheduledStart) {
      AppHaptics.warning();
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsStartEventTooEarly,
          type: AppSnackType.warning,
        );
      }
      return;
    }
    await _withCtaMutationBusy(() async {
      try {
        final bool changed = await _eventsStore.updateStatus(
          event.id,
          EcoEventStatus.inProgress,
        );
        if (!changed) {
          AppHaptics.warning();
          if (mounted) {
            AppSnack.show(
              context,
              message: context.l10n.eventsUnableToStartEventGeneric,
              type: AppSnackType.warning,
            );
          }
          return;
        }
      } on AppError catch (e) {
        AppHaptics.warning();
        if (mounted) {
          AppSnack.show(
            context,
            message: localizedAppErrorMessage(context.l10n, e),
            type: AppSnackType.warning,
          );
        }
        return;
      }
      if (!mounted) {
        return;
      }
      final EcoEvent startedEvent =
          _eventsStore.findById(event.id) ??
          event.copyWith(status: EcoEventStatus.inProgress);
      EventsNavigation.openOrganizerCheckIn(context, eventId: startedEvent.id);
    });
  }

  void _handleManageCheckIn(EcoEvent event) {
    if (event.status != EcoEventStatus.inProgress) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsManageCheckInOnlyInProgress,
        type: AppSnackType.warning,
      );
      return;
    }
    EventsNavigation.openOrganizerCheckIn(context, eventId: event.id);
  }

  void _handleOpenCleanupEvidence(EcoEvent event) {
    if (!event.isOrganizer || event.status != EcoEventStatus.completed) {
      AppHaptics.warning();
      return;
    }
    AppHaptics.softTransition();
    EventsNavigation.openCleanupEvidence(context, eventId: event.id);
  }

  Future<void> _handleToggleJoin(EcoEvent event) async {
    if (!event.isJoined && !event.canVolunteerJoinNow) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsJoinWindowClosed,
        type: AppSnackType.warning,
      );
      return;
    }
    if (!event.isJoined &&
        event.maxParticipants != null &&
        event.participantCount >= event.maxParticipants!) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsEventFull,
        type: AppSnackType.warning,
      );
      return;
    }
    await _withCtaMutationBusy(() async {
      EcoEventJoinToggleResult joinResult = const EcoEventJoinToggleResult(
        changed: false,
      );
      try {
        joinResult = await _eventsStore.toggleJoin(event.id);
        if (!joinResult.changed) {
          AppHaptics.warning();
          if (mounted) {
            AppSnack.show(
              context,
              message: context.l10n.eventsParticipationUpdateFailed,
              type: AppSnackType.warning,
            );
          }
          return;
        }
      } on AppError catch (e) {
        AppHaptics.warning();
        if (mounted) {
          AppSnack.show(
            context,
            message: localizedAppErrorMessage(context.l10n, e),
            type: AppSnackType.warning,
          );
        }
        return;
      }
      if (!mounted) {
        return;
      }
      final EcoEvent? updated = _eventsStore.findById(event.id);
      if (updated != null) {
        unawaited(_refreshChatUnread(updated));
      }
      final bool joined = updated?.isJoined ?? false;
      final String message = !joined
          ? context.l10n.eventsLeftEcoAction
          : joinResult.pointsAwarded > 0
          ? context.l10n.eventsJoinPointsEarned(joinResult.pointsAwarded)
          : context.l10n.eventsJoinedEcoAction;
      AppSnack.show(context, message: message, type: AppSnackType.success);
    });
  }

  Future<void> _handleToggleReminder(EcoEvent event) async {
    AppHaptics.tap();
    if (!event.isJoined) {
      AppSnack.show(
        context,
        message: context.l10n.eventsJoinFirstForReminders,
        type: AppSnackType.warning,
      );
      return;
    }
    if (event.reminderEnabled) {
      await _withCtaMutationBusy(() async {
        try {
          final bool changed = await _eventsStore.setReminder(
            eventId: event.id,
            enabled: false,
            reminderAt: null,
          );
          if (changed) {
            if (mounted) {
              AppSnack.show(
                context,
                message: context.l10n.eventsReminderDisabled,
                type: AppSnackType.success,
              );
            }
          }
        } on AppError catch (e) {
          if (mounted) {
            AppSnack.show(
              context,
              message: localizedAppErrorMessage(context.l10n, e),
              type: AppSnackType.warning,
            );
          }
        }
      });
      return;
    }

    await _handleEnableReminder(event);
  }

  Future<void> _handleEnableReminder(EcoEvent event) async {
    final DateTime? selectedReminder = await ReminderPickerSheet.show(
      context,
      event,
    );
    if (!mounted || selectedReminder == null) {
      return;
    }
    await _withCtaMutationBusy(() async {
      try {
        final bool changed = await _eventsStore.setReminder(
          eventId: event.id,
          enabled: true,
          reminderAt: selectedReminder,
        );
        if (!changed) {
          return;
        }
      } on AppError catch (e) {
        if (mounted) {
          AppSnack.show(
            context,
            message: localizedAppErrorMessage(context.l10n, e),
            type: AppSnackType.warning,
          );
        }
        return;
      }
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsReminderSetSnack(
          ReminderPickerSheet.formatReminderLabel(selectedReminder),
        ),
        type: AppSnackType.success,
      );
    });
  }

  void _openEditEvent(EcoEvent event) {
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext sheetCtx) => EditEventSheet(event: event),
    );
  }

  void _openExtendCleanupEnd(EcoEvent event) {
    AppHaptics.tap();
    unawaited(
      showExtendEventEndSheet(
        context: context,
        event: event,
        eventsRepository: _eventsStore,
      ),
    );
  }

  bool _shouldShowOrganizerEndSoonBanner(EcoEvent event) {
    if (!event.isOrganizer || event.status != EcoEventStatus.inProgress) {
      return false;
    }
    final DateTime threshold = event.endDateTime.subtract(
      const Duration(minutes: 10),
    );
    return !DateTime.now().isBefore(threshold);
  }

  Future<void> _handleAddToCalendar(EcoEvent event) async {
    AppHaptics.softTransition();
    try {
      await EventCalendarExport.addToCalendar(event);
      if (!mounted) {
        return;
      }
      AppHaptics.light();
      AppSnack.show(
        context,
        message: context.l10n.eventsDetailCalendarAdded,
        type: AppSnackType.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsDetailCalendarFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _handleOpenAttendeeCheckIn(EcoEvent event) async {
    if (event.isCheckedIn) {
      AppSnack.show(
        context,
        message: context.l10n.eventsAttendeeAlreadyCheckedInSnack,
        type: AppSnackType.success,
      );
      return;
    }
    if (!event.canOpenAttendeeCheckIn) {
      AppSnack.show(
        context,
        message: context.l10n.eventsAttendeeCheckInPausedSnack,
        type: AppSnackType.warning,
      );
      return;
    }
    AppHaptics.softTransition();
    final bool? success = await EventsNavigation.openAttendeeQrScanner(
      context,
      eventId: event.id,
    );
    if (!mounted || success != true) {
      return;
    }
    AppSnack.show(
      context,
      message: context.l10n.eventsAttendeeCheckInCompleteSnack,
      type: AppSnackType.success,
    );
  }

  void _openFullscreenGallery(
    BuildContext context,
    EcoEvent event,
    int initialIndex,
  ) {
    AppHaptics.softTransition();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) =>
            FullscreenGalleryPage(event: event, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent? event = _eventsStore.findById(widget.eventId);

    if (!_detailPrefetchDone && event == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: Text(context.l10n.authLoading),
        ),
        body: AnimatedPhaseSwitcher(
          phaseKey: 'skeleton',
          child: const EventDetailSkeleton(),
        ),
      );
    }

    if (event == null || _detailMissing) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: Text(context.l10n.eventsEventNotFoundTitle),
        ),
        body: const EventDetailNotFoundView(),
      );
    }

    final double scrollBottomInset = _scrollBottomInset(context, event);

    if (ServiceLocator.instance.isInitialized) {
      unawaited(
        _organizerEndSoonLocal.sync(
          event: event,
          push: ServiceLocator.instance.pushNotificationService,
          l10n: context.l10n,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Semantics(
        label: context.l10n.eventsDetailSemanticsLabel(event.title),
        child: Stack(
          children: <Widget>[
            RefreshIndicator(
              color: AppColors.primary,
              displacement: 48,
              strokeWidth: 2.2,
              onRefresh: _handlePullToRefresh,
              child: CustomScrollView(
                controller: _detailScrollController,
                physics: eventDetailScrollPhysics(context),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                  HeroImageBar(
                      event: event,
                      innerBoxIsScrolled: _heroCollapsedEnoughForBodyScroll,
                      enableThumbnailHero: widget.enableThumbnailHero,
                      onEdit:
                          event.isOrganizer &&
                              (event.status == EcoEventStatus.upcoming ||
                                  event.status == EcoEventStatus.inProgress)
                          ? () {
                              AppHaptics.tap();
                              _openEditEvent(event);
                            }
                          : null,
                      onOpenEventChat: _canOpenEventChat(event)
                          ? () => _openEventChat(event)
                          : null,
                      eventChatUnreadCount: _chatUnreadCount,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          kEventDetailBodyHorizontalGutter,
                          kEventDetailBodyHorizontalGutter,
                          kEventDetailBodyHorizontalGutter,
                          scrollBottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                          if (_showStaleDetailBanner) ...<Widget>[
                            Semantics(
                              container: true,
                              label:
                                  '${context.l10n.eventsDetailCouldNotRefresh}. ${context.l10n.eventsDetailRetryRefresh}',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  ReportInfoBanner(
                                    message: context
                                        .l10n
                                        .eventsDetailCouldNotRefresh,
                                    icon: CupertinoIcons
                                        .exclamationmark_circle_fill,
                                    tone: ReportSurfaceTone.warning,
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton(
                                      onPressed: () =>
                                          unawaited(_retryDetailRefresh()),
                                      child: Text(
                                        context.l10n.eventsDetailRetryRefresh,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (event.isDeclined &&
                              event.isOrganizer) ...<Widget>[
                            ReportInfoBanner(
                              title: context.l10n.eventsDeclinedBannerTitle,
                              message: context.l10n.eventsDeclinedBannerBody,
                              icon: CupertinoIcons.xmark_circle_fill,
                              tone: ReportSurfaceTone.danger,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ] else if (!event.moderationApproved &&
                              event.isOrganizer) ...<Widget>[
                            ReportInfoBanner(
                              title: context.l10n.eventsModerationBannerTitle,
                              message: context.l10n.eventsModerationBannerBody,
                              icon: CupertinoIcons.info_circle_fill,
                              tone: ReportSurfaceTone.accent,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (!event.moderationApproved &&
                              !event.isOrganizer) ...<Widget>[
                            ReportInfoBanner(
                              title: context
                                  .l10n
                                  .eventsAttendeeModerationBannerTitle,
                              message: context
                                  .l10n
                                  .eventsAttendeeModerationBannerBody,
                              icon: CupertinoIcons.hourglass,
                              tone: ReportSurfaceTone.accent,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (_shouldShowOrganizerEndSoonBanner(
                            event,
                          )) ...<Widget>[
                            ReportInfoBanner(
                              title: context.l10n.eventsEndSoonBannerTitle,
                              message: context.l10n.eventsEndSoonBannerBody,
                              icon: CupertinoIcons.clock_fill,
                              tone: ReportSurfaceTone.accent,
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: () => _openExtendCleanupEnd(event),
                                child: Text(
                                  context.l10n.eventsEndSoonBannerExtend,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          DetailContent(
                            event: event,
                            onToggleReminder: () =>
                                _handleToggleReminder(event),
                            onExportCalendar: () => _handleAddToCalendar(event),
                            feedbackSnapshot: _feedbackSnapshot,
                            onEditFeedback: () => _editFeedback(event),
                            onImageTap: (int index) =>
                                _openFullscreenGallery(context, event, index),
                            onOpenSeriesOccurrence: (String id) {
                              if (id == widget.eventId) {
                                return;
                              }
                              EventsNavigation.replaceDetail(
                                context,
                                eventId: id,
                              );
                            },
                            onSaveBagsCollected:
                                event.isOrganizer &&
                                    event.status == EcoEventStatus.completed
                                ? (int bags) => _saveBagsCollected(event, bags)
                                : null,
                            onOpenImpactReceipt: event.status == EcoEventStatus.inProgress ||
                                    event.status == EcoEventStatus.completed
                                ? () => EventsNavigation.openImpactReceipt(
                                      context,
                                      eventId: event.id,
                                    )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StickyBottomCTA(
              event: event,
              isPrimaryLoading: _ctaMutationBusy,
              onToggleJoin: () => _handleToggleJoin(event),
              onToggleReminder: () => _handleToggleReminder(event),
              onStartEvent: () => _handleStartEvent(event),
              onManageCheckIn: () => _handleManageCheckIn(event),
              onOpenAttendeeCheckIn: () => _handleOpenAttendeeCheckIn(event),
              onOpenCleanupEvidence: () => _handleOpenCleanupEvidence(event),
              onExtendCleanupEnd: () => _openExtendCleanupEnd(event),
            ),
          ],
        ),
      ),
    );
  }
}
