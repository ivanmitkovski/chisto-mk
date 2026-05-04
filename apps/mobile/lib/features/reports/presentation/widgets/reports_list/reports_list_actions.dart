import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_widgets.dart';
import 'package:flutter/material.dart';

/// Stable callback bundle for [ReportsListScreenSlivers] so the list body can
/// rebuild on [ListenableBuilder] without recreating many closure identities.
@immutable
class ReportsListActions {
  const ReportsListActions({
    required this.onRetryAfterError,
    required this.onStartNewReport,
    required this.onSearchSubmitted,
    required this.onSearchClear,
    required this.onOpenReportDetail,
    required this.onStatusFilterSelected,
    required this.formatReportDate,
  });

  final VoidCallback onRetryAfterError;
  final VoidCallback onStartNewReport;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onSearchClear;
  final void Function(ReportListItem report) onOpenReportDetail;
  final void Function(ReportSheetStatus? status) onStatusFilterSelected;
  final String Function(DateTime date) formatReportDate;
}
