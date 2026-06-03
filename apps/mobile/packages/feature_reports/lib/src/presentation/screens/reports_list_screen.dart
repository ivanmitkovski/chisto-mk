library;

import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/data/report_image_prefetch_coordinator.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_event.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_draft_summary.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/presentation/controllers/reports_list_controller.dart';
import 'package:feature_reports/src/presentation/controllers/reports_list_state.dart';
import 'package:feature_reports/src/presentation/flow/report_entry_flow.dart';
import 'package:feature_reports/src/presentation/l10n/report_status_l10n.dart';
import 'package:feature_reports/src/presentation/widgets/draft/draft_choice_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/reports_list_actions.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/reports_list_realtime_coalescer.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/reports_list_empty_state.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/reports_list_screen_slivers.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/reports_list_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part '../widgets/reports_list/reports_list_bootstrap.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen>
    with StateRebuildMixin {
  late final DefaultReportImagePrefetchCoordinator _prefetchCoordinator =
      DefaultReportImagePrefetchCoordinator();

  ReportSheetStatus? _statusFilter;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  StreamSubscription<ReportsOwnerEvent>? _realtimeSub;
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
  ReportsListController get _list =>
      ref.read(reportsListControllerProvider.notifier);

  Object? _bootstrappedListIdentity;
  Listenable? _draftSummaryListenable;
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

  List<ReportListItem> _filteredReports(
    AppLocalizations l10n,
    ReportsListState listState,
  ) {
    List<ReportListItem> list = listState.reports;
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

  String _searchResultSummaryLabel(
    AppLocalizations l10n,
    ReportsListState listState,
  ) {
    final List<ReportListItem> filtered = _filteredReports(l10n, listState);
    if (_searchQuery.isEmpty) return '';
    if (filtered.isEmpty) return l10n.reportListSearchNoMatches;
    if (filtered.length == 1) return l10n.reportListSearchOneReport;
    return l10n.reportListSearchNReports(filtered.length);
  }

  @override
  void initState() {
    super.initState();
    bootstrapInitState();
  }

  @override
  void didUpdateWidget(ReportsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bootstrapDidUpdateWidget(oldWidget);
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
    _realtimeSub?.cancel();
    bootstrapDispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _loadReports();
  }

  Future<void> _openReportDetailById(String id) async {
    if (_isOpeningReportDetail) return;
    _isOpeningReportDetail = true;
    if (mounted) setState(() {});
    widget.onReportOpened?.call();
    final RequestCancellationToken cancellation = _beginReportDetailFetch();
    try {
      final detail = await ref
          .read(reportsApiRepositoryProvider)
          .getReportById(id, cancellation: cancellation);
      if (!mounted) return;
      final ReportSheetViewModel display =
          ReportSheetViewModelMapper.fromDetail(detail, context.l10n);
      unawaited(_prefetchCoordinator.warmDetail(id, detail.mediaUrls, context));
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
    final RequestCancellationToken cancellation = _beginReportDetailFetch();
    try {
      final detail = await ref
          .read(reportsApiRepositoryProvider)
          .getReportById(report.id, cancellation: cancellation);
      if (!mounted) return;
      final ReportSheetViewModel display =
          ReportSheetViewModelMapper.fromDetail(detail, context.l10n);
      unawaited(
        _prefetchCoordinator.warmDetail(report.id, detail.mediaUrls, context),
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
      sheetAnimationStyle: const AnimationStyle(
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
      shape: const RoundedRectangleBorder(
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
                  reportsRealtimeService: ref.read(
                    reportsRealtimeServiceProvider,
                  ),
                  reportsApiRepository: ref.read(reportsApiRepositoryProvider),
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
    bootstrapListenInBuild();
    final ReportsListState listState = ref.watch(reportsListControllerProvider);
    bootstrapEnsureInitialLoad(_list);
    final AppLocalizations l10n = context.l10n;
    final List<ReportListItem> filteredReports = _filteredReports(
      l10n,
      listState,
    );
    final bool showStatusFilter =
        !listState.isLoadingFirstPage && listState.loadError == null;
    return SafeArea(
      bottom: false,
      child: AppRefreshIndicator(
        onRefresh: _handleRefresh,
        child: ReportsListScreenSlivers(
          scrollController: _scrollController,
          listState: listState,
          l10n: l10n,
          filteredReports: filteredReports,
          showStatusFilter: showStatusFilter,
          reportCapacity: _reportCapacity,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          searchResultSummaryLabel: _searchResultSummaryLabel(l10n, listState),
          actions: _listActions,
          statusFilter: _statusFilter,
          apiStatusToDisplay: _apiStatusToDisplay,
          emptyWhenNoReports: _buildEmptyState(context),
          emptyWhenFiltered: _buildFilterEmptyState(context),
          showFilteredCountFooter:
              !listState.isLoadingFirstPage && filteredReports.isNotEmpty,
        ),
      ),
    );
  }

  void _selectStatusFilter(ReportSheetStatus? status) {
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

    return ReportsListFilterEmptyState(
      message: message,
      hint: hint,
      icon: icon,
      clearSearchLabel: hasSearch ? l10n.reportListClearSearch : null,
      onClearSearch: hasSearch
          ? () {
              _searchDebounce?.cancel();
              _searchController.clear();
              _searchFocusNode.unfocus();
              setState(() => _searchQuery = '');
            }
          : null,
    );
  }

  Future<void> _startNewReport() async {
    if (!await ReportEntryFlow.ensureReportingAllowed(context, ref: ref)) {
      return;
    }
    if (!mounted) {
      return;
    }
    final ReportDraftSummary summary = ref
        .read(reportDraftRepositoryProvider)
        .summaryListenable
        .value;
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
    if (!mounted || result == null) {
      return;
    }
    ReportEntryFlow.handleNewReportWizardPopResult(
      result,
      onViewSubmittedReport: (String reportId) async {
        await _loadReports();
        if (mounted) {
          await _openReportDetailById(reportId);
        }
      },
      onViewReportsList: () async {
        await _loadReports();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ReportsListEmptyState(onReportPollution: _startNewReport);
  }
}
