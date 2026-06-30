part of 'package:feature_events/src/presentation/screens/event_detail_screen.dart';

extension EventDetailRefreshCoordinator on _EventDetailScreenState {
  Duration _detailResumeRefreshTtl(EcoEvent event) {
    if (event.isCheckInOpen || event.status == EcoEventStatus.inProgress) {
      return _EventDetailScreenState._detailResumeRefreshTtlHot;
    }
    return _EventDetailScreenState._detailResumeRefreshTtlDefault;
  }

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
      rebuildState(() => _heroCollapsedEnoughForBodyScroll = next);
    }
  }

  bool _canOpenEventChat(EcoEvent e) =>
      (e.isJoined || e.isOrganizer) && e.status != EcoEventStatus.cancelled;

  Future<void> _refreshChatUnread(EcoEvent event) async {
    if (!_canOpenEventChat(event)) {
      if (mounted) {
        rebuildState(() => _chatUnreadCount = 0);
      }
      return;
    }
    try {
      final int c = await ref
          .read(eventChatRepositoryProvider)
          .fetchUnreadCount(widget.eventId);
      if (mounted) {
        rebuildState(() => _chatUnreadCount = c);
      }
    } on Object catch (_) {
      logEventsDiagnostic('detail_chat_unread_fetch_failed');
    }
  }

  void _openEventChat(EcoEvent event) {
    final Completer<void> readSync = Completer<void>();
    AppNavigation.pushEventChat(
      EventChatRouteArguments(
        eventId: event.id,
        eventTitle: event.title,
        isOrganizer: event.isOrganizer,
        readSyncCompleter: readSync,
      ),
    ).then((_) async {
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
    rebuildState(() => _ctaMutationBusy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        rebuildState(() => _ctaMutationBusy = false);
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
      rebuildState(() {
        if (fetched) {
          _localDetailRefreshFailed = false;
          _lastDetailRefreshAt = DateTime.now();
        }
      });
    } on Object {
      if (mounted) {
        rebuildState(() => _localDetailRefreshFailed = true);
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
      rebuildState(() {});
    });
  }

  void _schedulePushReminderSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final EcoEvent? event = _eventsStore.findById(widget.eventId);
      final PushNotificationService? push = _pushForLocalReminders;
      if (event == null || push == null) {
        return;
      }
      unawaited(
        _organizerEndSoonLocal.sync(
          event: event,
          push: push,
          l10n: context.l10n,
        ),
      );
      unawaited(
        _attendeeReminderLocal.sync(
          event: event,
          push: push,
          l10n: context.l10n,
        ),
      );
    });
  }

  void _onStoreChanged() {
    if (!mounted) {
      return;
    }
    void applyUpdate() {
      if (!mounted) {
        return;
      }
      rebuildState(() {});
      _ensureJoinWindowTicker();
      _schedulePushReminderSync();
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
    rebuildState(() {
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
        rebuildState(() {
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
        rebuildState(() => _localDetailRefreshFailed = false);
        final EcoEvent? refreshed = _eventsStore.findById(widget.eventId);
        if (refreshed != null) {
          unawaited(_refreshChatUnread(refreshed));
        }
      } else if (_eventsStore.findById(widget.eventId) != null) {
        rebuildState(() => _localDetailRefreshFailed = true);
      }
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      logEventsDiagnostic('events_detail_refresh_failed');
      if (_eventsStore.findById(widget.eventId) != null) {
        rebuildState(() => _localDetailRefreshFailed = true);
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
        rebuildState(() => _localDetailRefreshFailed = true);
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
        rebuildState(() => _localDetailRefreshFailed = false);
      }
    } on Object {
      if (mounted && _eventsStore.findById(widget.eventId) != null) {
        rebuildState(() => _localDetailRefreshFailed = true);
      }
    }
  }
}
