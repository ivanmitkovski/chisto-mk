import 'dart:async';
import 'dart:io';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/evidence_carousel.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:flutter/material.dart';

enum _ReportStatus {
  underReview('Under review', Color(0xFFF5A623), Color(0xFFFFF8EC)),
  approved('Approved', Color(0xFF2FD788), Color(0xFFEDFFF6)),
  declined('Declined', Color(0xFFE6513D), Color(0xFFFFF0EE)),
  alreadyReported('Already reported', Color(0xFF5B8DEF), Color(0xFFEDF3FF));

  const _ReportStatus(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;
}

class _MockReport {
  const _MockReport({
    required this.title,
    required this.description,
    required this.status,
    required this.score,
    required this.category,
    this.address,
    this.declineReason,
    this.evidenceImagePaths,
    this.cleanupEffort,
    required this.createdAt,
  });

  final String title;
  final String description;
  final _ReportStatus status;
  final int score;
  final ReportCategory category;
  final String? address;
  final String? declineReason;
  final List<String>? evidenceImagePaths;
  final CleanupEffort? cleanupEffort;
  final DateTime createdAt;
}

final List<_MockReport> _seedReportsCatalog = <_MockReport>[
  _MockReport(
    title: 'Illegal dump near river',
    description:
        'Large pile of mixed waste accumulating near the Vardar riverbank.',
    status: _ReportStatus.underReview,
    score: 0,
    category: ReportCategory.illegalLandfill,
    address: 'Vardar riverbank, Skopje',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  _MockReport(
    title: 'Construction debris on road',
    description:
        'Broken bricks and concrete blocking the sidewalk on main street.',
    status: _ReportStatus.approved,
    score: 50,
    category: ReportCategory.industrialWaste,
    address: 'Main St. 15, Skopje',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  _MockReport(
    title: 'Tire dump behind factory',
    description:
        'Dozens of old tires piled up behind the abandoned textile factory.',
    status: _ReportStatus.declined,
    score: 0,
    category: ReportCategory.illegalLandfill,
    address: 'Industrial zone, Kumanovo',
    declineReason: 'Duplicate report — already tracked under site #42.',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
  ),
  _MockReport(
    title: 'Plastic waste in park',
    description:
        'Scattered plastic bags and bottles around the central park benches.',
    status: _ReportStatus.alreadyReported,
    score: 0,
    category: ReportCategory.other,
    address: 'City Park, Bitola',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
  ),
];

class ReportsListMockStore {
  const ReportsListMockStore._();

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static final List<_MockReport> _submittedReports = <_MockReport>[];

  static List<_MockReport> get _reports => <_MockReport>[
    ..._submittedReports,
    ..._seedReportsCatalog,
  ];

  static void addSubmittedDraft(ReportDraft draft) {
    final ReportCategory category = draft.category ?? ReportCategory.other;
    final String trimmedDescription = draft.description.trim();
    final String? trimmedAddress = draft.address?.trim();

    _submittedReports.insert(
      0,
      _MockReport(
        title: '${category.label} report',
        description: trimmedDescription.isNotEmpty
            ? trimmedDescription
            : 'Citizen report awaiting moderation and site review.',
        status: _ReportStatus.underReview,
        score: 0,
        category: category,
        address: trimmedAddress != null && trimmedAddress.isNotEmpty
            ? trimmedAddress
            : 'Pinned location in Macedonia',
        evidenceImagePaths:
            draft.photos.map((XFile file) => file.path).toList(),
        cleanupEffort: draft.cleanupEffort,
        createdAt: DateTime.now(),
      ),
    );
    changes.value++;
  }
}

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 220);

  bool _isLoading = true;
  _ReportStatus? _statusFilter;
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

  bool _reportMatchesQuery(_MockReport r, List<String> tokens) {
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

  int _reportSearchScore(_MockReport r, List<String> tokens) {
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

  List<_MockReport> get _filteredReports {
    List<_MockReport> list = _reports;
    if (_statusFilter != null) {
      list = list.where((_MockReport r) => r.status == _statusFilter!).toList();
    }
    final List<String> tokens = _searchTokens(_searchQuery);
    if (tokens.isEmpty) return list;
    list = list.where((_MockReport r) => _reportMatchesQuery(r, tokens)).toList();
    list = List<_MockReport>.from(list)
      ..sort((_MockReport a, _MockReport b) {
        final int scoreA = _reportSearchScore(a, tokens);
        final int scoreB = _reportSearchScore(b, tokens);
        return scoreB.compareTo(scoreA);
      });
    return list;
  }

  List<_MockReport> get _reports => ReportsListMockStore._reports;

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
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _entranceController?.forward();
    });
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
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {});
    }
  }

  void _openReportDetail(_MockReport report) {
    AppHaptics.softTransition();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _ReportDetailSheet(report: report),
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
    final List<_MockReport> filteredReports = _filteredReports;
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
            if (!_isLoading && _reports.isNotEmpty)
              SliverToBoxAdapter(child: _buildStatusFilter(context)),
            if (_isLoading)
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
                    final _MockReport report = filteredReports[index];
                    final AnimationController? controller = _entranceController;
                    final Widget card = _ReportCard(
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
          (_MockReport report) => report.status == _ReportStatus.underReview,
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
    final List<_MockReport> filtered = _filteredReports;
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(), // transparent, no border
          child: Row(
            children: <Widget>[
              Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search your reports',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                      letterSpacing: -0.3,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
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
                    padding: const EdgeInsets.only(left: 6),
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
            _FilterChip(
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
            const SizedBox(width: 8),
            ..._ReportStatus.values.map(
              (_ReportStatus status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
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
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.tap();
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() => _searchQuery = '');
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
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
              borderRadius: BorderRadius.circular(20),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter${selected ? ' selected' : ''}',
      hint: 'Double-tap to filter reports by $label.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onTap,
    required this.formatDate,
  });

  final _MockReport report;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final List<String> evidencePaths = report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage =
        evidencePaths.isNotEmpty && File(evidencePaths.first).existsSync();

    return Semantics(
      button: true,
      label: '${report.title}. ${report.status.label}. Tap to view details.',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 0.5),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: hasEvidenceImage
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    AppSmartImage(
                                      image: FileImage(
                                        File(evidencePaths.first),
                                      ),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            Colors.black.withValues(
                                              alpha: 0.24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: Icon(
                                    report.category.icon,
                                    size: 28,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: <Widget>[
                                      _StatusBadge(status: report.status),
                                      Text(
                                        formatDate(report.createdAt),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    if (report.score > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.emoji_events_rounded,
                                            size: 18,
                                            color: const Color(0xFFF5A623),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+${report.score}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFF5A623),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 22,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (hasEvidenceImage)
                              const ReportStatePill(
                                label: 'Photo attached',
                                icon: Icons.image_outlined,
                                tone: ReportSurfaceTone.neutral,
                              ),
                            if (hasEvidenceImage) const SizedBox(height: 6),
                            Text(
                              report.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                            ),
                            if (report.address != null &&
                                report.address!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      report.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (report.declineReason != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    ReportInfoBanner(
                      title: 'Review note',
                      message: report.declineReason!,
                      icon: Icons.info_outline_rounded,
                      tone: ReportSurfaceTone.warning,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.report});

  final _MockReport report;

  static String _formatDateFull(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final List<String> evidencePaths = report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage =
        evidencePaths.isNotEmpty && File(evidencePaths.first).existsSync();

    return ReportSheetScaffold(
      title: 'Report details',
      subtitle: 'See what you submitted and how moderators handled this report.',
      trailing: ReportCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: 'Close',
        onTap: () {
          AppHaptics.tap();
          Navigator.of(context).pop();
        },
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (hasEvidenceImage) ...<Widget>[
              EvidenceCarousel(photoPaths: evidencePaths),
              const SizedBox(height: AppSpacing.md),
            ],
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                _StatusBadge(status: report.status),
                ReportStatePill(
                  label: _formatDateFull(report.createdAt),
                  icon: Icons.schedule_rounded,
                  tone: ReportSurfaceTone.neutral,
                ),
                if (hasEvidenceImage)
                  const ReportStatePill(
                    label: 'Photo attached',
                    icon: Icons.image_outlined,
                    tone: ReportSurfaceTone.accent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: report.category.icon,
              label: 'Category',
              child: Text(
                report.category.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
              ),
            ),
            if (report.cleanupEffort != null)
              _DetailRow(
                icon: Icons.groups_2_outlined,
                label: 'Cleanup effort',
                child: Text(
                  report.cleanupEffort!.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
            if (report.score > 0)
              _DetailRow(
                icon: Icons.emoji_events_rounded,
                label: 'Points',
                child: Text(
                  '+${report.score}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5A623),
                  ),
                ),
              ),
            if (report.address != null && report.address!.isNotEmpty)
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                child: Text(
                  report.address!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        letterSpacing: -0.2,
                      ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              report.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.divider.withValues(alpha: 0.7), height: 1),
            const SizedBox(height: AppSpacing.lg),
            ReportInfoBanner(
              title: report.status == _ReportStatus.underReview
                  ? 'Under review by moderators'
                  : report.status == _ReportStatus.approved
                      ? 'Approved and linked to a site'
                      : report.status == _ReportStatus.alreadyReported
                          ? 'Already tracked as an existing site'
                          : 'Review outcome',
              icon: report.status == _ReportStatus.approved
                  ? Icons.verified_outlined
                  : report.status == _ReportStatus.declined
                      ? Icons.info_outline_rounded
                      : Icons.schedule_rounded,
              tone: report.status == _ReportStatus.approved
                  ? ReportSurfaceTone.success
                  : report.status == _ReportStatus.declined
                      ? ReportSurfaceTone.danger
                      : report.status == _ReportStatus.alreadyReported
                          ? ReportSurfaceTone.warning
                          : ReportSurfaceTone.neutral,
              message: report.status == _ReportStatus.underReview
                  ? 'Moderators are checking your evidence and location before they decide how to handle this report.'
                  : report.status == _ReportStatus.approved
                      ? 'This report helped confirm a public pollution site and may contribute to cleanup actions.'
                      : report.status == _ReportStatus.alreadyReported
                          ? 'Your report matched an existing site. The evidence is still useful for understanding the problem.'
                          : report.declineReason ??
                              'This report could not be approved in its current form.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
