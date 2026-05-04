import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/reports_list_controller.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_card_skeleton.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_actions.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_realtime_banner.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_screen_header.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_widgets.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/animated_list_item.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:flutter/material.dart';

/// Body for [ReportsListScreen]: realtime banner, fixed list chrome (stats, search, filters),
/// then scrollable slivers. Chrome is **not** inside a fixed-height sliver so there is no
/// dead band between filters and the first card.
class ReportsListScreenSlivers extends StatelessWidget {
  const ReportsListScreenSlivers({
    super.key,
    required this.scrollController,
    required this.controller,
    required this.l10n,
    required this.filteredReports,
    required this.showStatusFilter,
    required this.reportCapacity,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchResultSummaryLabel,
    required this.actions,
    required this.statusFilter,
    required this.apiStatusToDisplay,
    required this.emptyWhenNoReports,
    required this.emptyWhenFiltered,
    required this.showFilteredCountFooter,
  });

  final ScrollController scrollController;
  final ReportsListController controller;
  final AppLocalizations l10n;
  final List<ReportListItem> filteredReports;
  final bool showStatusFilter;
  final ReportCapacity? reportCapacity;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchResultSummaryLabel;
  final ReportsListActions actions;
  final ReportSheetStatus? statusFilter;
  final ReportSheetStatus? Function(ApiReportStatus status) apiStatusToDisplay;
  final Widget emptyWhenNoReports;
  final Widget emptyWhenFiltered;
  final bool showFilteredCountFooter;

  List<Widget> _listSlivers(BuildContext context) {
    return <Widget>[
      if (controller.loadError != null)
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            error: controller.loadError!,
            onRetry: actions.onRetryAfterError,
          ),
        )
      else if (controller.isLoadingFirstPage && controller.reports.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.builder(
            itemCount: 5,
            itemBuilder: (BuildContext context, int index) =>
                const ReportCardSkeleton(),
          ),
        )
      else if (controller.reports.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: emptyWhenNoReports,
        )
      else if (filteredReports.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: emptyWhenFiltered,
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
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
              final ReportSheetViewModel display =
                  ReportSheetViewModelMapper.fromListItem(report, l10n);
              return AnimatedListItem(
                index: index,
                slideOffset: 14,
                child: ReportCard(
                  report: display,
                  onTap: () => actions.onOpenReportDetail(report),
                  formatDate: actions.formatReportDate,
                ),
              );
            },
          ),
        ),
      if (controller.isAppending)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      if (showFilteredCountFooter)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.xl,
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            child: Center(
              child: Text(
                statusFilter == null
                    ? l10n.reportListFilteredFooterAll
                    : l10n.reportListFilteredFooterCount(
                        filteredReports.length,
                      ),
                style: AppTypography.reportsSheetSubtitle(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ReportsListRealtimeBanner(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ReportsListStatsHeader(
                totalReports: controller.reports.length,
                underReviewCount: controller.reports
                    .where(
                      (ReportListItem r) =>
                          apiStatusToDisplay(r.status) ==
                          ReportSheetStatus.underReview,
                    )
                    .length,
                reportCapacity: reportCapacity,
                l10n: l10n,
                onStartNewReport: actions.onStartNewReport,
              ),
              ReportsListSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                resultSummaryLabel: searchResultSummaryLabel,
                onSubmitted: actions.onSearchSubmitted,
                onClear: actions.onSearchClear,
              ),
              if (showStatusFilter)
                ReportsListStatusFilterBar(
                  selected: statusFilter,
                  onSelected: actions.onStatusFilterSelected,
                ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: _listSlivers(context),
          ),
        ),
      ],
    );
  }
}
