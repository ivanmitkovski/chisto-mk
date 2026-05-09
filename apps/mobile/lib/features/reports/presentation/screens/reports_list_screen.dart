import 'dart:async';

import 'package:intl/intl.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/reports/data/report_image_prefetch_coordinator.dart';
import 'package:chisto_mobile/features/reports/data/reports_realtime/reports_owner_event.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/reports_list_controller.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_summary_projector.dart';
import 'package:chisto_mobile/features/reports/presentation/flow/report_entry_flow.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/draft/draft_choice_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_status_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_actions.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_realtime_coalescer.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_screen_slivers.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_widgets.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({
    super.key,
    this.initialReportIdToOpen,
    this.onReportOpened,
    this.refreshTrigger,
    this.onShowSiteOnMap,
    this.onOpenLinkedPollutionSiteDetail,
  });

  final String? initialReportIdToOpen;
  final VoidCallback? onReportOpened;
  final int? refreshTrigger;
  final void Function(String siteId)? onShowSiteOnMap;

  /// Shell (e.g. home tab host) implements site fetch + in-app pollution site navigation.
  final Future<void> Function(String siteId, ReportSheetViewModel snapshot)?
      onOpenLinkedPollutionSiteDetail;

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  static final Duration _searchDebounceDuration = AppMotion.medium;
  static final Duration _minSkeletonDuration =
      AppMotion.reportsListSkeletonMinHold;

  late final ReportsListController _listController = ReportsListController(
    repository: ServiceLocator.instance.reportsApiRepository,
  );
  late final DefaultReportImagePrefetchCoordinator _prefetchCoordinator =
      DefaultReportImagePrefetchCoordinator(ServiceLocator.instance.preferences);

  ReportSheetStatus? _statusFilter;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  StreamSubscription? _realtimeSub;
  late final ReportsListRealtimeCoalescer _realtimeCoalescer =
      ReportsListRealtimeCoalescer(
    debounce: AppMotion.reportsListRealtimeCoalesce,
    onRefresh: () {
      if (!mounted) return;
      _loadReports();
    },
  );
  late final ReportsListActions _listActions = ReportsListActions(
    onRetryAfterError: () {
      unawaited(_loadReports());
    },
    onStartNewReport: () {
      unawaited(_startNewReport());
    },
    onSearchSubmitted: _onSearchSubmitted,
    onSearchClear: _onSearchClear,
    onOpenReportDetail: _openReportDetail,
    onStatusFilterSelected: _selectStatusFilter,
    formatReportDate: _formatReportDate,
  );
  String _searchQuery = '';
  bool _isOpeningReportDetail = false;
  RequestCancellationToken? _reportDetailFetchCancellation;
  ReportCapacity? _reportCapacity;

  RequestCancellationToken _beginReportDetailFetch() {
    _reportDetailFetchCancellation?.cancel();
    final RequestCancellationToken token = RequestCancellationToken();
    _reportDetailFetchCancellation = token;
    return token;
  }

  void _endReportDetailFetch(RequestCancellationToken token) {
    if (identical(_reportDetailFetchCancellation, token)) {
      _reportDetailFetchCancellation = null;
    }
  }

  List<String> _searchTokens(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalized.isEmpty) return <String>[];
    return normalized.split(' ').where((String s) => s.isNotEmpty).toList();
  }

  bool _reportMatchesQuery(
    ReportListItem r,
    List<String> tokens,
    AppLocalizations l10n,
  ) {
    final String title = r.title.toLowerCase();
    final String address = r.location.toLowerCase();
    final String category = (r.category?.apiString ?? 'other').toLowerCase();
    for (final String token in tokens) {
      final bool matches =
          title.contains(token) ||
          address.contains(token) ||
          category.contains(token) ||
          apiReportStatusMatchesSearchToken(l10n, r.status, token);
      if (!matches) return false;
    }
    return true;
  }

  int _reportSearchScore(ReportListItem r, List<String> tokens) {
    final String title = r.title.toLowerCase();
    final String address = r.location.toLowerCase();
    final String category = (r.category?.apiString ?? 'other').toLowerCase();
    int score = 0;
    for (final String token in tokens) {
      if (title.contains(token)) score += 10;
      if (address.contains(token)) score += 8;
      if (category.contains(token)) score += 6;
    }
    return score;
  }

  ReportSheetStatus? _apiStatusToDisplay(ApiReportStatus s) {
    switch (s) {
      case ApiReportStatus.new_:
      case ApiReportStatus.inReview:
        return ReportSheetStatus.underReview;
      case ApiReportStatus.approved:
        return ReportSheetStatus.approved;
      case ApiReportStatus.deleted:
        return ReportSheetStatus.declined;
    }
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

  List<ReportListItem> _filteredReports(AppLocalizations l10n) {
    List<ReportListItem> list = _listController.reports;
    if (_statusFilter != null) {
      list = list
          .where(
            (ReportListItem r) =>
                _apiStatusToDisplay(r.status) == _statusFilter!,
          )
          .toList();
    }
    final List<String> tokens = _searchTokens(_searchQuery);
    if (tokens.isEmpty) return list;
    list = list
        .where((ReportListItem r) => _reportMatchesQuery(r, tokens, l10n))
        .toList();
    list = List<ReportListItem>.from(list)
      ..sort((ReportListItem a, ReportListItem b) {
        final int scoreA = _reportSearchScore(a, tokens);
        final int scoreB = _reportSearchScore(b, tokens);
        return scoreB.compareTo(scoreA);
      });
    return list;
  }

  String _searchResultSummaryLabel(AppLocalizations l10n) {
    final List<ReportListItem> filtered = _filteredReports(l10n);
    if (_searchQuery.isEmpty) return '';
    if (filtered.isEmpty) return l10n.reportListSearchNoMatches;
    if (filtered.length == 1) return l10n.reportListSearchOneReport;
    return l10n.reportListSearchNReports(filtered.length);
  }

  @override
  void initState() {
    super.initState();
    _listController.addListener(_onListControllerChanged);
    _scrollController.addListener(_onScrollNearEnd);
    _searchController.addListener(_onSearchChanged);
    _searchQuery = _searchController.text.trim();
    _loadReports();
    ServiceLocator.instance.reportsListSession.attach(_listController);
    _realtimeSub = ServiceLocator.instance.reportsRealtimeService.events.listen(
      _onReportsOwnerEvent,
    );
    ServiceLocator.instance.reportDraftRepository.summaryListenable.addListener(
      _onDraftSummaryChanged,
    );
    if (widget.initialReportIdToOpen != null &&
        widget.initialReportIdToOpen!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openReportDetailById(widget.initialReportIdToOpen!);
      });
    }
  }

  @override
  void didUpdateWidget(ReportsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  void _onDraftSummaryChanged() {
    if (mounted) {
      setState(() {});
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
    // List UI rebuilds via [ListenableBuilder] on [_listController]; avoid full-screen
    // setState on every list notification (pagination, realtime updates).
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
      setState(() {});
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
      final ReportCapacity capacity = await ServiceLocator
          .instance
          .reportsApiRepository
          .getReportingCapacity();
      if (!mounted) return;
      setState(() => _reportCapacity = capacity);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reportCapacity = null);
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      final String next = _searchController.text.trim();
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
  }

  void _onSearchSubmitted() {
    _searchFocusNode.unfocus();
    _searchDebounce?.cancel();
    setState(() => _searchQuery = _searchController.text.trim());
  }

  void _onSearchClear() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  void dispose() {
    ServiceLocator.instance.reportDraftRepository.summaryListenable.removeListener(
      _onDraftSummaryChanged,
    );
    _prefetchCoordinator.cancel();
    ServiceLocator.instance.reportsListSession.detach(_listController);
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
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    await _loadReports();
  }

  Future<void> _openReportDetailById(String id) async {
    if (_isOpeningReportDetail) return;
    _isOpeningReportDetail = true;
    if (mounted) setState(() {});
    AppHaptics.softTransition();
    widget.onReportOpened?.call();
    final RequestCancellationToken cancellation = _beginReportDetailFetch();
    try {
      final detail = await ServiceLocator.instance.reportsApiRepository
          .getReportById(id, cancellation: cancellation);
      if (!mounted) return;
      final ReportSheetViewModel display =
          ReportSheetViewModelMapper.fromDetail(detail, context.l10n);
      unawaited(
        _prefetchCoordinator.warmDetail(id, detail.mediaUrls, context),
      );
      await _showReportDetailSheet(display);
    } on AppError catch (e) {
      if (e.code == 'CANCELLED') return;
      if (!mounted) return;
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
    } finally {
      _endReportDetailFetch(cancellation);
      _isOpeningReportDetail = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _openReportDetail(ReportListItem report) async {
    if (_isOpeningReportDetail) return;
    _isOpeningReportDetail = true;
    if (mounted) setState(() {});
    AppHaptics.softTransition();
    final RequestCancellationToken cancellation = _beginReportDetailFetch();
    try {
      final detail = await ServiceLocator.instance.reportsApiRepository
          .getReportById(report.id, cancellation: cancellation);
      if (!mounted) return;
      final ReportSheetViewModel display =
          ReportSheetViewModelMapper.fromDetail(detail, context.l10n);
      unawaited(
        _prefetchCoordinator.warmDetail(
          report.id,
          detail.mediaUrls,
          context,
        ),
      );
      await _showReportDetailSheet(display);
    } on AppError catch (e) {
      if (e.code == 'CANCELLED') return;
      if (!mounted) return;
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
    } catch (_) {
      if (!mounted) return;
      final ReportSheetViewModel display =
          ReportSheetViewModelMapper.fromListItem(report, context.l10n);
      await _showReportDetailSheet(display);
    } finally {
      _endReportDetailFetch(cancellation);
      _isOpeningReportDetail = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showReportDetailSheet(ReportSheetViewModel report) {
    return showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.standard,
        curve: AppMotion.smooth,
      ),
      isScrollControlled: true,
      // true: avoid Flutter's removeTop padding strip (content under notch/Dynamic
      // Island). Modal SafeArea uses bottom:false so the sheet still reaches the
      // physical bottom above the home indicator via inner padding.
      useSafeArea: true,
      // Root overlay so the sheet covers the home shell bottom bar + FAB.
      useRootNavigator: true,
      backgroundColor: AppColors.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      builder: (BuildContext sheetContext) {
        final double keyboardInset = MediaQuery.viewInsetsOf(
          sheetContext,
        ).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SizedBox(
                height: constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : null,
                width: constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : null,
                child: ReportDetailSheet(
                  report: report,
                  onShowSiteOnMap: widget.onShowSiteOnMap,
                  onOpenLinkedPollutionSiteDetail:
                      widget.onOpenLinkedPollutionSiteDetail,
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatReportDate(DateTime d) {
    final AppLocalizations l10n = context.l10n;
    final Duration diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return l10n.eventsDateRelativeToday;
    if (diff.inDays == 1) return l10n.profilePointsHistoryDayYesterday;
    if (diff.inDays < 7) return l10n.eventsDateRelativeDaysAgo(diff.inDays);
    if (diff.inDays < 30) {
      final int weeks = (diff.inDays / 7).floor();
      return l10n.reportListDateWeeksAgo(weeks);
    }
    final String locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        onRefresh: _handleRefresh,
        child: ListenableBuilder(
          listenable: _listController,
          builder: (BuildContext context, Widget? child) {
            final List<ReportListItem> filteredReports = _filteredReports(l10n);
            final bool showStatusFilter =
                !_listController.isLoadingFirstPage &&
                _listController.loadError == null;
            return ReportsListScreenSlivers(
              scrollController: _scrollController,
              controller: _listController,
              l10n: l10n,
              filteredReports: filteredReports,
              showStatusFilter: showStatusFilter,
              reportCapacity: _reportCapacity,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchResultSummaryLabel: _searchResultSummaryLabel(l10n),
              actions: _listActions,
              statusFilter: _statusFilter,
              apiStatusToDisplay: _apiStatusToDisplay,
              emptyWhenNoReports: _buildEmptyState(context),
              emptyWhenFiltered: _buildFilterEmptyState(context),
              showFilteredCountFooter:
                  !_listController.isLoadingFirstPage &&
                  filteredReports.isNotEmpty,
            );
          },
        ),
      ),
    );
  }

  void _selectStatusFilter(ReportSheetStatus? status) {
    AppHaptics.tap();
    setState(() => _statusFilter = status);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppMotion.medium,
        curve: AppMotion.smooth,
      );
    }
  }

  Widget _buildFilterEmptyState(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool hasSearch = _searchQuery.isNotEmpty;
    final bool hasFilter = _statusFilter != null;
    final String message = hasSearch
        ? l10n.reportListNoMatchesSearchTitle
        : l10n.reportListNoMatchesFilterTitle;
    final IconData icon = hasSearch
        ? Icons.search_off_rounded
        : Icons.filter_list_off_rounded;
    final String hint = hasSearch && hasFilter
        ? l10n.reportListNoMatchesHintSearchAndFilter
        : hasSearch
        ? l10n.reportListNoMatchesHintSearchOnly
        : l10n.reportListNoMatchesHintFilterOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTypography.emptyStateTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppTypography.emptyStateSubtitle.copyWith(height: 1.4),
          ),
          if (hasSearch) ...[
            const SizedBox(height: AppSpacing.lg),
            Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.tap();
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() => _searchQuery = '');
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.reportListClearSearch,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startNewReport() async {
    AppHaptics.medium();
    if (!await ReportEntryFlow.ensureReportingAllowed(context)) {
      return;
    }
    if (!mounted) {
      return;
    }
    final ReportDraftSummary summary =
        ServiceLocator.instance.reportDraftRepository.summaryListenable.value;
    if (summary.hasDraft) {
      final CentralFabDraftChoice? choice =
          await ReportEntryFlow.promptDraftChoiceIfNeeded(
        context: context,
        summary: summary,
      );
      if (!mounted) {
        return;
      }
      if (choice == CentralFabDraftChoice.cancel || choice == null) {
        return;
      }
      if (choice == CentralFabDraftChoice.takeNewPhoto) {
        await ReportEntryFlow.openCameraThenNewReport(context: context);
        if (mounted) {
          await _loadReports();
        }
        return;
      }
    }
    final String newReportEntryLabel = context.l10n.newReportTitle;
    final Object? result = await ReportEntryFlow.openNewReportWizard(
      context,
      entryLabel: newReportEntryLabel,
    );
    if (result != null && mounted) {
      await _loadReports();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 30,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.reportListEmptyTitle,
            style: AppTypography.emptyStateTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.reportListEmptySubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.emptyStateSubtitle.copyWith(height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            button: true,
            label: context.l10n.reportListFabLabel,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startNewReport,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(context.l10n.reportListFabLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radius18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
