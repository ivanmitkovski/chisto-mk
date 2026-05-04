import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

/// Owns server-backed paging for "My reports". Search and status filters stay
/// in the screen; this controller holds the merged [reports] list.
class ReportsListController extends ChangeNotifier {
  ReportsListController({required ReportsApiRepository repository})
      : _repository = repository;

  final ReportsApiRepository _repository;

  RequestCancellationToken? _firstPageToken;
  RequestCancellationToken? _appendToken;

  List<ReportListItem> reports = <ReportListItem>[];
  bool isLoadingFirstPage = true;
  bool isAppending = false;
  AppError? loadError;
  AppError? appendLoadError;
  int _serverPage = 1;
  bool hasMore = true;

  static const int pageSize = 20;

  @override
  void dispose() {
    _firstPageToken?.cancel();
    _appendToken?.cancel();
    super.dispose();
  }

  void clearAppendError() {
    appendLoadError = null;
    notifyListeners();
  }

  void _beginFirstPageRequest() {
    _firstPageToken?.cancel();
    _firstPageToken = RequestCancellationToken();
    _appendToken?.cancel();
  }

  Future<void> refreshFirstPage() async {
    _beginFirstPageRequest();
    final RequestCancellationToken token = _firstPageToken!;

    final bool showFullSkeleton = reports.isEmpty;
    if (showFullSkeleton) {
      isLoadingFirstPage = true;
      loadError = null;
      appendLoadError = null;
      notifyListeners();
    } else {
      loadError = null;
      appendLoadError = null;
      notifyListeners();
    }

    try {
      final ReportsListResponse response = await _repository.getMyReports(
        page: 1,
        limit: pageSize,
        cancellation: token,
      );
      token.throwIfCancelled();
      if (!identical(_firstPageToken, token)) {
        return;
      }
      reports = response.data;
      _serverPage = 1;
      hasMore = response.hasMore;
      loadError = null;
      appendLoadError = null;
    } on AppError catch (e) {
      if (e.code == 'CANCELLED' || !identical(_firstPageToken, token)) {
        return;
      }
      loadError = e;
      if (reports.isEmpty) {
        reports = <ReportListItem>[];
      }
    } finally {
      if (identical(_firstPageToken, token)) {
        isLoadingFirstPage = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadNextPage() async {
    if (!hasMore || isAppending || isLoadingFirstPage || reports.isEmpty) {
      return;
    }
    _appendToken?.cancel();
    _appendToken = RequestCancellationToken();
    final RequestCancellationToken token = _appendToken!;

    isAppending = true;
    appendLoadError = null;
    notifyListeners();

    try {
      final int nextPage = _serverPage + 1;
      final ReportsListResponse response = await _repository.getMyReports(
        page: nextPage,
        limit: pageSize,
        cancellation: token,
      );
      token.throwIfCancelled();
      if (!identical(_appendToken, token)) {
        return;
      }
      reports = <ReportListItem>[...reports, ...response.data];
      _serverPage = nextPage;
      hasMore = response.hasMore;
    } on AppError catch (e) {
      if (e.code == 'CANCELLED' || !identical(_appendToken, token)) {
        return;
      }
      appendLoadError = e;
    } finally {
      if (identical(_appendToken, token)) {
        isAppending = false;
        notifyListeners();
      }
    }
  }

  /// Inserts a client-optimistic row after POST /reports succeeds (reconciled via SSE).
  void insertOptimisticFromSubmit(
    ReportSubmitResult result,
    String title,
    ReportDraft draft,
  ) {
    if (result.reportId.isEmpty) {
      return;
    }
    final int existing = reports.indexWhere((ReportListItem r) => r.id == result.reportId);
    if (existing != -1) {
      return;
    }
    final String location = draft.address?.trim().isNotEmpty == true
        ? draft.address!.trim()
        : '';
    final ReportListItem item = ReportListItem(
      id: result.reportId,
      reportNumber: (result.reportNumber != null && result.reportNumber!.isNotEmpty)
          ? result.reportNumber!
          : '…',
      title: title,
      description: draft.description.trim().isNotEmpty ? draft.description.trim() : null,
      location: location,
      submittedAt: DateTime.now(),
      status: ApiReportStatus.new_,
      isPotentialDuplicate: false,
      coReporterCount: 0,
      mediaUrls: List<String>.from(result.submittedMediaUrls),
      pointsAwarded: result.pointsAwarded,
      category: draft.category,
      severity: draft.severity,
      cleanupEffort: draft.cleanupEffort,
      viewerRole: ReportViewerRole.primary,
      isOptimistic: true,
    );
    reports = <ReportListItem>[item, ...reports];
    notifyListeners();
  }

  void clearOptimisticForReport(String reportId) {
    final int idx = reports.indexWhere((ReportListItem r) => r.id == reportId && r.isOptimistic);
    if (idx == -1) {
      return;
    }
    reports = List<ReportListItem>.from(reports)
      ..[idx] = reports[idx].copyWith(isOptimistic: false);
    notifyListeners();
  }

  void removeReportById(String reportId) {
    reports = reports.where((ReportListItem r) => r.id != reportId).toList();
    notifyListeners();
  }

  void applyStatusFromApi(String reportId, String statusRaw) {
    final int idx = reports.indexWhere((ReportListItem r) => r.id == reportId);
    if (idx == -1) {
      return;
    }
    final ApiReportStatus next = parseApiReportStatusFromApi(statusRaw);
    reports = List<ReportListItem>.from(reports)
      ..[idx] = reports[idx].copyWith(status: next, isOptimistic: false);
    notifyListeners();
  }
}
