import 'dart:async';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_widgets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 220);

  bool _isLoading = true;
  AppError? _loadError;
  ReportStatus? _statusFilter;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  AnimationController? _entranceController;
  Timer? _searchDebounce;
  String _searchQuery = '';

  List<String> _searchTokens(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return <String>[];
    return normalized.split(' ').where((String s) => s.isNotEmpty).toList();
  }

  bool _reportMatchesQuery(MockReport r, List<String> tokens) {
    final String title = r.title.toLowerCase();
    final String desc = r.description.toLowerCase();
    final String address = (r.address ?? '').toLowerCase();
    final String category = r.category.label.toLowerCase();
    final String statusLabel = r.status.label.toLowerCase();
    final String decline = (r.declineReason ?? '').toLowerCase();
    for (final String token in tokens) {
      final bool matches = title.contains(token) ||
          desc.contains(token) ||
          address.contains(token) ||
          category.contains(token) ||
          statusLabel.contains(token) ||
          decline.contains(token);
      if (!matches) return false;
    }
    return true;
  }

  int _reportSearchScore(MockReport r, List<String> tokens) {
    final String title = r.title.toLowerCase();
    final String address = (r.address ?? '').toLowerCase();
    final String category = r.category.label.toLowerCase();
    final String desc = r.description.toLowerCase();
    int score = 0;
    for (final String token in tokens) {
      if (title.contains(token)) score += 10;
      if (address.contains(token)) score += 8;
      if (category.contains(token)) score += 6;
      if (desc.contains(token)) score += 2;
    }
    return score;
  }

  List<MockReport> get _filteredReports {
    List<MockReport> list = _reports;
    if (_statusFilter != null) {
      list = list.where((MockReport r) => r.status == _statusFilter!).toList();
    }
    final List<String> tokens = _searchTokens(_searchQuery);
    if (tokens.isEmpty) return list;
    list = list.where((MockReport r) => _reportMatchesQuery(r, tokens)).toList();
    list = List<MockReport>.from(list)
      ..sort((MockReport a, MockReport b) {
        final int scoreA = _reportSearchScore(a, tokens);
        final int scoreB = _reportSearchScore(b, tokens);
        return scoreB.compareTo(scoreA);
      });
    return list;
  }

  List<MockReport> get _reports => ReportsListMockStore.reports;

  @override
  void initState() {
    super.initState();
    ReportsListMockStore.changes.addListener(_onStoreChanged);
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _searchController.addListener(_onSearchChanged);
    _searchQuery = _searchController.text.trim();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
      _entranceController?.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = AppError.network(cause: e);
        _isLoading = false;
      });
      if (mounted) {
        AppSnack.show(
          context,
          message: 'No connection',
          type: AppSnackType.warning,
        );
      }
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

  void _onStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    ReportsListMockStore.changes.removeListener(_onStoreChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _entranceController?.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    await _loadReports();
  }

  void _openReportDetail(MockReport report) {
    AppHaptics.softTransition();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) => ReportDetailSheet(report: report),
    );
  }

  static String _formatDate(DateTime d) {
    final Duration diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} wk ago';
    return '${d.day}.${d.month}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final List<MockReport> filteredReports = _filteredReports;
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
            if (!_isLoading && _loadError == null && _reports.isNotEmpty)
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
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDark,
                    strokeWidth: 2.5,
                  ),
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList.builder(
                  itemCount: filteredReports.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= filteredReports.length) {
                      return const SizedBox.shrink();
                    }
                    final MockReport report = filteredReports[index];
                    final AnimationController? controller = _entranceController;
                    final Widget card = ReportCard(
                      report: report,
                      onTap: () => _openReportDetail(report),
                      formatDate: _formatDate,
                    );

                    if (controller == null) return card;
                    final double stagger = (index * 0.15).clamp(0.0, 0.6);
                    final double staggerEnd = (stagger + 0.4).clamp(0.0, 1.0);
                    final Animation<double> opacity = CurvedAnimation(
                      parent: controller,
                      curve: Interval(
                        stagger,
                        staggerEnd,
                        curve: AppMotion.standardCurve,
                      ),
                    );
                    final Animation<Offset> slide =
                        Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: controller,
                            curve: Interval(
                              stagger,
                              staggerEnd,
                              curve: AppMotion.emphasized,
                            ),
                          ),
                        );
                    return FadeTransition(
                      opacity: opacity,
                      child: SlideTransition(position: slide, child: card),
                    );
                  },
                ),
              ),
            if (!_isLoading && _filteredReports.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.xl,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Center(
                    child: Text(
                      _statusFilter == null
                          ? 'All reports shown'
                          : '${_filteredReports.length} report${_filteredReports.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          (MockReport report) => report.status == ReportStatus.underReview,
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
            'Your reports',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'See every pollution report you have sent and how it was handled.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            label:
                '$totalReports report${totalReports == 1 ? '' : 's'} in total. $underReviewCount currently under review.',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                ReportStatePill(
                  label:
                      '$totalReports report${totalReports == 1 ? '' : 's'} in total',
                  icon: Icons.description_outlined,
                ),
                ReportStatePill(
                  label: '$underReviewCount under review',
                  icon: Icons.schedule_rounded,
                  tone: underReviewCount > 0
                      ? ReportSurfaceTone.warning
                      : ReportSurfaceTone.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final bool hasSearchText = _searchController.text.isNotEmpty;
    final List<MockReport> filtered = _filteredReports;
    final String resultLabel = _searchQuery.isEmpty
        ? ''
        : filtered.isEmpty
            ? 'No matches'
            : filtered.length == 1
                ? '1 report'
                : '${filtered.length} reports';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Semantics(
        label: 'Search reports',
        hint: 'Search by title, location, category, or status. $resultLabel'.trim(),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius14),
          decoration: const BoxDecoration(),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search your reports',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                      letterSpacing: -0.3,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                    isDense: true,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    _searchFocusNode.unfocus();
                    _searchDebounce?.cancel();
                    setState(
                      () => _searchQuery = _searchController.text.trim(),
                    );
                  },
                ),
              ),
              if (hasSearchText)
                GestureDetector(
                  onTap: () {
                    AppHaptics.tap();
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted.withValues(alpha: 0.85),
                    ),
                  ),
                )
              else if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    _filteredReports.isEmpty
                        ? 'No matches'
                        : _filteredReports.length == 1
                            ? '1 report'
                            : '${_filteredReports.length} reports',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                          color: _filteredReports.isEmpty
                              ? AppColors.textMuted.withValues(alpha: 0.9)
                              : AppColors.textSecondary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            ReportFilterChip(
              label: 'All',
              selected: _statusFilter == null,
              onTap: () {
                AppHaptics.tap();
                setState(() => _statusFilter = null);
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: AppMotion.fast,
                    curve: AppMotion.emphasized,
                  );
                }
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            ...ReportStatus.values.map(
              (ReportStatus status) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ReportFilterChip(
                  label: status.label,
                  selected: _statusFilter == status,
                  onTap: () {
                    AppHaptics.tap();
                    setState(() => _statusFilter = status);
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: AppMotion.fast,
                        curve: AppMotion.emphasized,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(BuildContext context) {
    final bool hasSearch = _searchQuery.isNotEmpty;
    final bool hasFilter = _statusFilter != null;
    final String message = hasSearch
        ? 'No reports found'
        : 'No reports with this filter';
    final IconData icon = hasSearch
        ? Icons.search_off_rounded
        : Icons.filter_list_off_rounded;
    final String hint = hasSearch && hasFilter
        ? 'Try a different search or clear filters to see more reports.'
        : hasSearch
            ? 'Check the spelling or try a broader search.'
            : 'Try another filter, or clear it to see all reports.';

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
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
                    'Clear search',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
            'No reports yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your future reports will appear here after you submit them.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
