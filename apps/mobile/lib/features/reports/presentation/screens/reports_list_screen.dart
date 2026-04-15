import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_card_skeleton.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_status_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_widgets.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/animated_list_item.dart';
import 'package:chisto_mobile/shared/widgets/app_pill_filter_chips.dart';
import 'package:flutter/material.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({
    super.key,
    this.initialReportIdToOpen,
    this.onReportOpened,
    this.refreshTrigger,
    this.onShowSiteOnMap,
  });

  final String? initialReportIdToOpen;
  final VoidCallback? onReportOpened;
  final int? refreshTrigger;
  final void Function(String siteId)? onShowSiteOnMap;

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 220);
  static const Duration _minSkeletonDuration = Duration(milliseconds: 400);
  static const Duration _realtimeRefreshDebounce = Duration(milliseconds: 450);

  bool _isLoading = true;
  AppError? _loadError;
  ReportStatus? _statusFilter;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  Timer? _realtimeDebounce;
  StreamSubscription? _realtimeSub;
  String _searchQuery = '';
  bool _isOpeningReportDetail = false;
  ReportCapacity? _reportCapacity;

  List<String> _searchTokens(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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
      final bool matches = title.contains(token) ||
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

  ReportStatus? _apiStatusToDisplay(ApiReportStatus s) {
    switch (s) {
      case ApiReportStatus.new_:
      case ApiReportStatus.inReview:
        return ReportStatus.underReview;
      case ApiReportStatus.approved:
        return ReportStatus.approved;
      case ApiReportStatus.deleted:
        return ReportStatus.declined;
    }
  }

  List<ReportListItem> _filteredReports(AppLocalizations l10n) {
    List<ReportListItem> list = _reports;
    if (_statusFilter != null) {
      list = list
          .where((ReportListItem r) => _apiStatusToDisplay(r.status) == _statusFilter!)
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

  List<ReportListItem> _reports = <ReportListItem>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchQuery = _searchController.text.trim();
    _loadReports();
    ServiceLocator.instance.reportsRealtimeService.start();
    _realtimeSub = ServiceLocator.instance.reportsRealtimeService.events.listen((_) {
      _realtimeDebounce?.cancel();
      _realtimeDebounce = Timer(_realtimeRefreshDebounce, () {
        if (!mounted) return;
        _loadReports();
      });
    });
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
    if (id != null &&
        id.isNotEmpty &&
        id != oldWidget.initialReportIdToOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openReportDetailById(id);
      });
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final response = await ServiceLocator.instance.reportsApiRepository
          .getMyReports(page: 1, limit: 50);
      if (!mounted) return;
      final int elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < _minSkeletonDuration.inMilliseconds) {
        await Future<void>.delayed(
          Duration(
            milliseconds: _minSkeletonDuration.inMilliseconds - elapsed,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _reports = response.data;
        _isLoading = false;
        _loadError = null;
      });
      _loadReportCapacityHint();
    } on AppError catch (e) {
      if (!mounted) return;
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'ACCOUNT_NOT_ACTIVE') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      setState(() {
        _loadError = e;
        _isLoading = false;
      });
      if (mounted) {
        AppSnack.show(context, message: e.message, type: AppSnackType.warning);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = AppError.network(cause: e);
        _isLoading = false;
      });
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.profileNoConnectionSnack,
          type: AppSnackType.warning,
        );
      }
    }
  }

  Future<void> _loadReportCapacityHint() async {
    try {
      final ReportCapacity capacity =
          await ServiceLocator.instance.reportsApiRepository.getReportingCapacity();
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeDebounce?.cancel();
    _realtimeSub?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
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
    try {
      final detail = await ServiceLocator.instance.reportsApiRepository
          .getReportById(id);
      if (!mounted) return;
      final MockReport display =
          ReportsListMockStore.fromDetail(detail, context.l10n);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: false,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        builder: (BuildContext sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ReportDetailSheet(
            report: display,
            onShowSiteOnMap: widget.onShowSiteOnMap,
          ),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
    } finally {
      _isOpeningReportDetail = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _openReportDetail(ReportListItem report) async {
    if (_isOpeningReportDetail) return;
    _isOpeningReportDetail = true;
    if (mounted) setState(() {});
    AppHaptics.softTransition();
    try {
      final detail = await ServiceLocator.instance.reportsApiRepository
          .getReportById(report.id);
      if (!mounted) return;
      final MockReport display =
          ReportsListMockStore.fromDetail(detail, context.l10n);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: false,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        builder: (BuildContext sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ReportDetailSheet(
            report: display,
            onShowSiteOnMap: widget.onShowSiteOnMap,
          ),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
    } catch (_) {
      if (!mounted) return;
      final MockReport display =
          ReportsListMockStore.fromListItem(report, context.l10n);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: false,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        builder: (BuildContext sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ReportDetailSheet(
            report: display,
            onShowSiteOnMap: widget.onShowSiteOnMap,
          ),
        ),
      );
    } finally {
      _isOpeningReportDetail = false;
      if (mounted) setState(() {});
    }
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
    final List<ReportListItem> filteredReports = _filteredReports(l10n);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.panelBackground,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            if (!_isLoading && _loadError == null)
              SliverToBoxAdapter(child: _buildStatusFilter(context)),
            if (_loadError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorView(
                  error: _loadError!,
                  onRetry: _loadReports,
                ),
              )
            else if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverList.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) => const ReportCardSkeleton(),
                ),
              )
            else if (_reports.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else if (filteredReports.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildFilterEmptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverList.builder(
                  itemCount: filteredReports.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= filteredReports.length) {
                      return const SizedBox.shrink();
                    }
                    final ReportListItem report = filteredReports[index];
                    final MockReport display =
                        ReportsListMockStore.fromListItem(report, l10n);
                    return AnimatedListItem(
                      index: index,
                      slideOffset: 14,
                      child: ReportCard(
                        report: display,
                        onTap: () => _openReportDetail(report),
                        formatDate: _formatReportDate,
                      ),
                    );
                  },
                ),
              ),
            if (!_isLoading && _filteredReports(l10n).isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.xl,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Center(
                    child: Text(
                      _statusFilter == null
                          ? l10n.reportListFilteredFooterAll
                          : l10n.reportListFilteredFooterCount(
                              filteredReports.length,
                            ),
                      style: AppTypography.textTheme.bodySmall!.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final int totalReports = _reports.length;
    final int underReviewCount = _reports
        .where(
          (ReportListItem r) => _apiStatusToDisplay(r.status) == ReportStatus.underReview,
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.reportListHeaderTitle,
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            label: context.l10n.reportListHeaderSemanticSummary(
              totalReports,
              underReviewCount,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                ReportStatePill(
                  label: context.l10n.reportListHeaderTotalPill(totalReports),
                  icon: Icons.description_outlined,
                ),
                ReportStatePill(
                  label: context.l10n.reportListHeaderUnderReviewPill(
                    underReviewCount,
                  ),
                  icon: Icons.schedule_rounded,
                  tone: underReviewCount > 0
                      ? ReportSurfaceTone.warning
                      : ReportSurfaceTone.neutral,
                ),
                if (_reportCapacity != null)
                  Builder(
                    builder: (BuildContext context) {
                      final ReportCapacityUiState ui =
                          mapReportCapacityToUiState(
                        _reportCapacity!,
                        l10n: context.l10n,
                        nextEmergencyAvailableDescription:
                            formatNextEmergencyUnlockLocal(
                          context,
                          _reportCapacity!.nextEmergencyReportAvailableAt,
                        ),
                      );
                      return ReportStatePill(
                        label: ui.pillLabel,
                        icon: ui.pillIcon,
                        tone: ui.pillTone,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final List<ReportListItem> filtered = _filteredReports(context.l10n);
    final AppLocalizations l10n = context.l10n;
    final String resultLabel = _searchQuery.isEmpty
        ? ''
        : filtered.isEmpty
            ? l10n.reportListSearchNoMatches
            : filtered.length == 1
                ? l10n.reportListSearchOneReport
                : l10n.reportListSearchNReports(filtered.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Semantics(
        label: l10n.reportListSearchSemantic,
        hint: '${l10n.reportListSearchHintPrefix} $resultLabel'.trim(),
        child: CupertinoSearchTextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          placeholder: l10n.reportListSearchPlaceholder,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          placeholderStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.radius10,
          ),
          backgroundColor: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onSubmitted: (_) {
            _searchFocusNode.unfocus();
            _searchDebounce?.cancel();
            setState(() => _searchQuery = _searchController.text.trim());
          },
          onSuffixTap: () {
            AppHaptics.tap();
            _searchDebounce?.cancel();
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> labels = <String>[
      l10n.reportListFilterAll,
      ...ReportStatus.values.map(
        (ReportStatus s) => reportUiStatusShortLabel(l10n, s),
      ),
    ];
    final int selectedIndex = _statusFilter == null
        ? 0
        : ReportStatus.values.indexOf(_statusFilter!) + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppPillFilterChips(
        labels: labels,
        selectedIndex: selectedIndex,
        semanticLabelPrefix: l10n.reportListFilterSemanticPrefix,
        onSelected: (int index) {
          AppHaptics.tap();
          setState(() {
            _statusFilter =
                index == 0 ? null : ReportStatus.values[index - 1];
          });
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: AppMotion.medium,
              curve: AppMotion.smooth,
            );
          }
        },
      ),
    );
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
          Text(
            message,
            style: AppTypography.emptyStateTitle,
          ),
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
                    style: AppTypography.buttonLabel.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
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
    final bool canProceed = await _ensureCanStartReportFlow();
    if (!canProceed) return;
    if (!mounted) return;
    final String newReportEntryLabel = context.l10n.newReportTitle;
    final Object? result = await Navigator.of(context).push<Object>(
      MaterialPageRoute<Object>(
        builder: (_) => NewReportScreen(
          entryLabel: newReportEntryLabel,
        ),
      ),
    );
    if (result != null && mounted) {
      await _loadReports();
    }
  }

  Future<bool> _ensureCanStartReportFlow() async {
    try {
      final capacity = await ServiceLocator.instance.reportsApiRepository.getReportingCapacity();
      if (capacity.creditsAvailable > 0 || capacity.emergencyAvailable) {
        return true;
      }
      if (!mounted) return false;
      return showReportingCooldownDialog(context, capacity);
    } on AppError catch (e) {
      if (!mounted) return false;
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'ACCOUNT_NOT_ACTIVE') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return false;
      }
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
      return false;
    } catch (_) {
      if (!mounted) return false;
      AppSnack.show(
        context,
        message: context.l10n.reportAvailabilityCheckFailedSnack,
        type: AppSnackType.warning,
      );
      return false;
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
