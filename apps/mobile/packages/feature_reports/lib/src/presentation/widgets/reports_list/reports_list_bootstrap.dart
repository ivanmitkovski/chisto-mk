part of 'package:feature_reports/src/presentation/screens/reports_list_screen.dart';

/// Init, realtime, pagination, and first-page load for [ReportsListScreen].
extension ReportsListBootstrap on _ReportsListScreenState {
  static const Duration _searchDebounceDuration = AppMotion.medium;
  static const Duration _minSkeletonDuration =
      AppMotion.reportsListSkeletonMinHold;

  void bootstrapListenInBuild() {
    ref.listen(reportsListControllerProvider, (
      ReportsListState? previous,
      ReportsListState next,
    ) {
      _onListControllerChanged(next);
    });
  }

  /// Starts the first-page fetch once per [ReportsListController] instance (see
  /// [EventsFeedScreenState._ensureFeedBootstrapped]).
  void bootstrapEnsureInitialLoad(ReportsListController list) {
    final Object identity = list;
    if (identical(_bootstrappedListIdentity, identity)) {
      return;
    }
    _bootstrappedListIdentity = identity;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_bootstrappedListIdentity, list)) {
        return;
      }
      final ReportsListState state = ref.read(reportsListControllerProvider);
      if (state.reports.isNotEmpty ||
          state.loadError != null ||
          !state.isLoadingFirstPage) {
        return;
      }
      unawaited(_loadReports());
    });
  }

  void bootstrapInitState() {
    _scrollController.addListener(_onScrollNearEnd);
    _searchController.addListener(_onSearchChanged);
    _searchQuery = _searchController.text.trim();
    final ReportsRealtimeService realtimeSvc = ref.read(
      reportsRealtimeServiceProvider,
    );
    final ReportsListController listController = ref.read(
      reportsListControllerProvider.notifier,
    );
    _reportsRealtimeService = realtimeSvc;
    _realtimeSub = realtimeSvc.events.listen(_onReportsOwnerEvent);
    if (ref.read(authStateProvider).isAuthenticated &&
        realtimeSvc.connectionState.value ==
            ReportsRealtimeConnectionState.offline) {
      realtimeSvc.requestReconnect();
    }
    void onConnectionChanged() {
      if (!mounted || _disposed) {
        return;
      }
      final ReportsRealtimeConnectionState? state =
          realtimeSvc.connectionState.value;
      _configureRestPollForConnection(state);
      if (state != ReportsRealtimeConnectionState.live) {
        return;
      }
      if (listController.reports.any((ReportListItem r) => r.isOptimistic)) {
        unawaited(_loadReports());
      }
    }

    realtimeSvc.connectionState.addListener(onConnectionChanged);
    _realtimeConnectionListener = onConnectionChanged;
    _configureRestPollForConnection(realtimeSvc.connectionState.value);
    _draftSummaryListenable = ref
        .read(reportDraftRepositoryProvider)
        .summaryListenable;
    _draftSummaryListenable!.addListener(_onDraftSummaryChanged);
    if (widget.initialReportIdToOpen != null &&
        widget.initialReportIdToOpen!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openReportDetailById(widget.initialReportIdToOpen!);
        }
      });
    }
  }

  void bootstrapDidUpdateWidget(ReportsListScreen oldWidget) {
    if (widget.refreshTrigger != null &&
        widget.refreshTrigger != oldWidget.refreshTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadReports();
      });
    }
    final String? id = widget.initialReportIdToOpen;
    if (id != null && id.isNotEmpty && id != oldWidget.initialReportIdToOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openReportDetailById(id);
      });
    }
  }

  void bootstrapDispose() {
    _draftSummaryListenable?.removeListener(_onDraftSummaryChanged);
    _draftSummaryListenable = null;
    final VoidCallback? connectionListener = _realtimeConnectionListener;
    if (connectionListener != null) {
      _reportsRealtimeService?.connectionState.removeListener(
        connectionListener,
      );
      _realtimeConnectionListener = null;
    }
    _reportsRealtimeService = null;
    _restPollTimer?.cancel();
    _restPollTimer = null;
    _prefetchCoordinator.cancel();
    _searchDebounce?.cancel();
    _realtimeCoalescer.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScrollNearEnd);
    _scrollController.dispose();
    _reportDetailFetchCancellation?.cancel();
  }

  void _onDraftSummaryChanged() {
    if (mounted && !_disposed) {
      rebuildState(() {});
    }
  }

  void _onListControllerChanged(ReportsListState listState) {
    final AppError? appendErr = listState.appendLoadError;
    if (appendErr != null && mounted) {
      AppSnack.failure(context, error: appendErr);
      _list.clearAppendError();
    }
  }

  void _onScrollNearEnd() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 600) {
      return;
    }
    unawaited(_list.loadNextPage());
  }

  Future<void> _loadReports() async {
    if (_disposed || !mounted) {
      return;
    }
    final bool wasEmpty = ref
        .read(reportsListControllerProvider)
        .reports
        .isEmpty;
    final Stopwatch stopwatch = Stopwatch()..start();
    await _list.refreshFirstPage();
    if (!mounted) {
      return;
    }
    final ReportsListState listState = ref.read(reportsListControllerProvider);
    if (wasEmpty && listState.loadError == null) {
      final int elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < _minSkeletonDuration.inMilliseconds) {
        await Future<void>.delayed(
          Duration(milliseconds: _minSkeletonDuration.inMilliseconds - elapsed),
        );
      }
    }
    final AppError? err = ref.read(reportsListControllerProvider).loadError;
    if (err != null) {
      if (SessionInvalidation.shouldHandle(err)) {
        unawaited(SessionInvalidation.fromError(err));
        return;
      }
      if (mounted) {
        AppSnack.failure(context, error: err);
      }
      return;
    }
    final List<ReportListItem> reports = ref
        .read(reportsListControllerProvider)
        .reports;
    if (reports.isNotEmpty && mounted) {
      unawaited(_prefetchCoordinator.warmList(reports, context));
    }
    unawaited(_loadReportCapacityHint());
  }

  Future<void> _loadReportCapacityHint() async {
    try {
      final ReportCapacity capacity = await ref
          .read(reportsApiRepositoryProvider)
          .getReportingCapacity();
      if (!mounted) return;
      rebuildState(() => _reportCapacity = capacity);
    } catch (_) {
      if (!mounted) return;
      rebuildState(() => _reportCapacity = null);
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      final String next = _searchController.text.trim();
      if (next == _searchQuery) return;
      rebuildState(() => _searchQuery = next);
    });
  }

  void _configureRestPollForConnection(ReportsRealtimeConnectionState? state) {
    _restPollTimer?.cancel();
    _restPollTimer = null;
    if (!mounted || _disposed) {
      return;
    }
    final ReportsRealtimeConnectionState resolved =
        state ?? ReportsRealtimeConnectionState.live;
    if (resolved == ReportsRealtimeConnectionState.live) {
      return;
    }
    _restPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _disposed) {
        return;
      }
      final ReportsRealtimeConnectionState? current =
          _reportsRealtimeService?.connectionState.value;
      if (current == ReportsRealtimeConnectionState.live) {
        _configureRestPollForConnection(current);
        return;
      }
      unawaited(_list.refreshFirstPage());
    });
  }

  void _onReportsOwnerEvent(ReportsOwnerEvent event) {
    if (!mounted || _disposed) {
      return;
    }
    if (event.type == 'report_created' && event.mutationKind == 'created') {
      _list.clearOptimisticForReport(event.reportId);
      _realtimeCoalescer.schedule();
      return;
    }
    if (event.type == 'report_updated' && event.mutationKind == 'merged') {
      _list.removeReportById(event.reportId);
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.reportsListMergedToast,
          type: AppSnackType.info,
        );
      }
      _realtimeCoalescer.schedule();
      return;
    }
    if (event.type == 'report_updated' &&
        event.mutationKind == 'status_changed' &&
        (event.status != null && event.status!.isNotEmpty)) {
      if (event.status!.toUpperCase() == 'DELETED') {
        _realtimeCoalescer.schedule();
      } else {
        _list.applyStatusFromApi(event.reportId, event.status!);
      }
      return;
    }
    _realtimeCoalescer.schedule();
  }
}
