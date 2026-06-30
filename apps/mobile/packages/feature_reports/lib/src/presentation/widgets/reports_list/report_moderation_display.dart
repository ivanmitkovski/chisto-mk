import 'package:feature_reports/src/domain/models/report_list_item.dart';

/// User-visible rejection copy from GET /reports when status is [ApiReportStatus.deleted].
String? declineReasonFromApi(ApiReportStatus status, String? moderationReason) {
  if (status != ApiReportStatus.deleted) {
    return null;
  }
  final String? trimmed = moderationReason?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
