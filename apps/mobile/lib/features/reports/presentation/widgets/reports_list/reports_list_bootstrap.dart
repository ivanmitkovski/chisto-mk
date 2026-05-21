part of 'package:chisto_mobile/features/reports/presentation/screens/reports_list_screen.dart';

/// Init, realtime, pagination, and first-page load for [ReportsListScreen].
extension ReportsListBootstrap on _ReportsListScreenState {
  static final Duration _searchDebounceDuration = AppMotion.medium;
  static final Duration _minSkeletonDuration =
      AppMotion.reportsListSkeletonMinHold;

  void bootstrapInitState() {
    _listController.addListener(_onListControllerChanged);
    _scrollController.addListener(_onScrollNearEnd);
    _searchController.addListener(_onSearchChanged);
    _searchQuery = _searchController.text.trim();
    _loadReports();
    readRoot(reportsListSessionProvider).attach(_listController);
    _realtimeSub = readRoot(reportsRealtimeServiceProvider).events.listen(
      _onReportsOwnerEvent,
    );
    readRoot(reportDraftRepositoryProvider).summaryListenable.addListener(
      _onDraftSummaryChanged,
    );
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
    readRoot(reportDraftRepositoryProvider).summaryListenable.removeListener(
      _onDraftSummaryChanged,
    );
    _prefetchCoordinator.cancel();
    readRoot(reportsListSessionProvider).detach(_listController);
    _listController.removeListener(_onListControllerChanged);
    _listController.dispose();
    _searchDebounce?.cancel();
    _realtimeCoalescer.dispose();
    _realtimeSub?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScrollNearEnd);
    _scrollController.dispose();
    _reportDetailFetchCancellation?.cancel();
  }

  void _onDraftSummaryChanged() {
    if (mounted) {
      rebuildState(() {});
    }
  }

  void _onListControllerChanged() {
    final AppError? appendErr = _listController.appendLoadError;
    if (appendErr != null && mounted) {
      AppSnack.show(
        context,
        message: appendErr.message,
        type: AppSnackType.warning,
      );
      _listController.clearAppendError();
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
    unawaited(_listController.loadNextPage());
  }

  Future<void> _loadReports() async {
    final bool wasEmpty = _listController.reports.isEmpty;
    final Stopwatch stopwatch = Stopwatch()..start();
    await _listController.refreshFirstPage();
    if (!mounted) {
      return;
    }
    if (wasEmpty && _listController.loadError == null) {
      final int elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < _minSkeletonDuration.inMilliseconds) {
        await Future<void>.delayed(
          Duration(
            milliseconds: _minSkeletonDuration.inMilliseconds - elapsed,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      rebuildState(() {});
    }
    final AppError? err = _listController.loadError;
    if (err != null) {
      if (err.code == 'UNAUTHORIZED' ||
          err.code == 'INVALID_TOKEN_USER' ||
          err.code == 'ACCOUNT_NOT_ACTIVE') {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      if (mounted) {
        AppSnack.show(
          context,
          message: err.message,
          type: AppSnackType.warning,
        );
      }
      return;
    }
    if (_listController.reports.isNotEmpty) {
      unawaited(
        _prefetchCoordinator.warmList(_listController.reports, context),
      );
    }
    unawaited(_loadReportCapacityHint());
  }

  Future<void> _loadReportCapacityHint() async {
    try {
      final ReportCapacity capacity =
          await readRoot(reportsApiRepositoryProvider).getReportingCapacity();
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

  void _onReportsOwnerEvent(ReportsOwnerEvent event) {
    if (event.type == 'report_created' && event.mutationKind == 'created') {
      _listController.clearOptimisticForReport(event.reportId);
      _realtimeCoalescer.schedule();
      return;
    }
    if (event.type == 'report_updated' && event.mutationKind == 'merged') {
      _listController.removeReportById(event.reportId);
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
      _listController.applyStatusFromApi(event.reportId, event.status!);
      return;
    }
    _realtimeCoalescer.schedule();
  }
}
