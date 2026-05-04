import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';

/// Paginated response from GET /reports/me.
class ReportsListResponse {
  const ReportsListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<ReportListItem> data;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}
