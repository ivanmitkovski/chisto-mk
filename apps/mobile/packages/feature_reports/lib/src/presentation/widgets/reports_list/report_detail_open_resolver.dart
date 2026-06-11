import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_reports/src/data/report_detail_cache.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';

/// Outcome of attempting to load report detail before opening the sheet.
sealed class ReportDetailOpenResolution {
  const ReportDetailOpenResolution();
}

final class ReportDetailOpenFresh extends ReportDetailOpenResolution {
  const ReportDetailOpenFresh(this.detail);

  final ReportDetail detail;
}

final class ReportDetailOpenStaleFallback extends ReportDetailOpenResolution {
  const ReportDetailOpenStaleFallback({
    required this.detail,
    required this.listItem,
    required this.error,
  });

  final ReportDetail? detail;
  final ReportListItem? listItem;
  final AppError error;

  bool get hasDetail => detail != null;
  bool get hasListItem => listItem != null;
}

final class ReportDetailOpenBlocked extends ReportDetailOpenResolution {
  const ReportDetailOpenBlocked(this.error);

  final AppError error;
}

bool isRecoverableReportDetailFetchError(
  AppError error, {
  required bool hasCachedContent,
}) {
  if (error.code == 'NETWORK_ERROR' || error.code == 'TIMEOUT') {
    return true;
  }
  if (hasCachedContent &&
      (error.code == 'SERVER_ERROR' ||
          error.code == 'INTERNAL_ERROR' ||
          error.code == 'DATABASE_UNAVAILABLE' ||
          error.code == 'DATABASE_TIMEOUT')) {
    return true;
  }
  return false;
}

Future<ReportDetailOpenResolution> resolveReportDetailForOpen({
  required ReportsApiRepository repository,
  required ReportDetailCacheStore cache,
  required String reportId,
  ReportListItem? listItem,
  RequestCancellationToken? cancellation,
}) async {
  try {
    final ReportDetail detail = await repository.getReportById(
      reportId,
      cancellation: cancellation,
    );
    cache.put(detail);
    return ReportDetailOpenFresh(detail);
  } on AppError catch (error) {
    if (error.code == 'CANCELLED') {
      rethrow;
    }
    final ReportDetail? cached = cache.get(reportId);
    final bool hasCachedContent = cached != null || listItem != null;
    if (isRecoverableReportDetailFetchError(
      error,
      hasCachedContent: hasCachedContent,
    )) {
      if (cached != null || listItem != null) {
        return ReportDetailOpenStaleFallback(
          detail: cached,
          listItem: listItem,
          error: error,
        );
      }
    }
    return ReportDetailOpenBlocked(error);
  }
}
