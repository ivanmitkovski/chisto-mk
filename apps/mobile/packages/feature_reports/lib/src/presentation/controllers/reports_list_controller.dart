import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/models/reports_list_response.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:feature_reports/src/presentation/controllers/reports_list_state.dart';
import 'package:feature_reports/src/presentation/theme/report_tokens.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_list_controller.g.dart';

/// Owns server-backed paging for "My reports". Search and status filters stay
/// in the screen; this controller holds the merged [reports] list.
@Riverpod(keepAlive: true)
class ReportsListController extends _$ReportsListController {
  late final ReportsApiRepository _repository;

  RequestCancellationToken? _firstPageToken;
  RequestCancellationToken? _appendToken;
  int _serverPage = 1;
  bool _alive = true;

  @override
  ReportsListState build() {
    _alive = true;
    _repository = ref.read(reportsApiRepositoryProvider);
    ref.onDispose(() {
      _alive = false;
      _firstPageToken?.cancel();
      _appendToken?.cancel();
    });
    return const ReportsListState();
  }

  static int get pageSize => ReportTokens.myReportsPageSize;

  List<ReportListItem> get reports => state.reports;
  bool get isLoadingFirstPage => state.isLoadingFirstPage;
  bool get isAppending => state.isAppending;
  AppError? get loadError => state.loadError;
  AppError? get appendLoadError => state.appendLoadError;
  bool get hasMore => state.hasMore;

  void clearAppendError() {
    state = state.copyWith(clearAppendLoadError: true);
  }

  void _beginFirstPageRequest() {
    _firstPageToken?.cancel();
    _firstPageToken = RequestCancellationToken();
    _appendToken?.cancel();
  }

  Future<void> refreshFirstPage() async {
    _beginFirstPageRequest();
    final RequestCancellationToken token = _firstPageToken!;

    final bool showFullSkeleton = state.reports.isEmpty;
    if (showFullSkeleton) {
      state = state.copyWith(
        isLoadingFirstPage: true,
        clearLoadError: true,
        clearAppendLoadError: true,
      );
    } else {
      state = state.copyWith(clearLoadError: true, clearAppendLoadError: true);
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
      state = state.copyWith(
        reports: mergeFirstPageWithOptimistic(
          serverPage: response.data,
          current: state.reports,
        ),
        hasMore: response.hasMore,
        clearLoadError: true,
        clearAppendLoadError: true,
      );
      _serverPage = 1;
    } on AppError catch (e) {
      if (e.code == 'CANCELLED' || !identical(_firstPageToken, token)) {
        return;
      }
      state = state.copyWith(
        loadError: e,
        reports: state.reports.isEmpty ? const <ReportListItem>[] : null,
      );
    } finally {
      if (_alive && identical(_firstPageToken, token)) {
        state = state.copyWith(isLoadingFirstPage: false);
      }
    }
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore ||
        state.isAppending ||
        state.isLoadingFirstPage ||
        state.reports.isEmpty) {
      return;
    }
    _appendToken?.cancel();
    _appendToken = RequestCancellationToken();
    final RequestCancellationToken token = _appendToken!;

    state = state.copyWith(isAppending: true, clearAppendLoadError: true);

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
      state = state.copyWith(
        reports: <ReportListItem>[...state.reports, ...response.data],
        hasMore: response.hasMore,
      );
      _serverPage = nextPage;
    } on AppError catch (e) {
      if (e.code == 'CANCELLED' || !identical(_appendToken, token)) {
        return;
      }
      state = state.copyWith(appendLoadError: e);
    } finally {
      if (_alive && identical(_appendToken, token)) {
        state = state.copyWith(isAppending: false);
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
    final int existing = state.reports.indexWhere(
      (ReportListItem r) => r.id == result.reportId,
    );
    if (existing != -1) {
      return;
    }
    final String location = draft.address?.trim().isNotEmpty ?? false
        ? draft.address!.trim()
        : '';
    final ReportListItem item = ReportListItem(
      id: result.reportId,
      reportNumber:
          (result.reportNumber != null && result.reportNumber!.isNotEmpty)
          ? result.reportNumber!
          : '…',
      title: title,
      description: draft.description.trim().isNotEmpty
          ? draft.description.trim()
          : null,
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
    state = state.copyWith(reports: <ReportListItem>[item, ...state.reports]);
  }

  void clearOptimisticForReport(String reportId) {
    final int idx = state.reports.indexWhere(
      (ReportListItem r) => r.id == reportId && r.isOptimistic,
    );
    if (idx == -1) {
      return;
    }
    final List<ReportListItem> updated = List<ReportListItem>.from(
      state.reports,
    )..[idx] = state.reports[idx].copyWith(isOptimistic: false);
    state = state.copyWith(reports: updated);
  }

  void removeReportById(String reportId) {
    state = state.copyWith(
      reports: state.reports
          .where((ReportListItem r) => r.id != reportId)
          .toList(),
    );
  }

  void applyStatusFromApi(String reportId, String statusRaw) {
    final int idx = state.reports.indexWhere(
      (ReportListItem r) => r.id == reportId,
    );
    if (idx == -1) {
      return;
    }
    final ApiReportStatus next = parseApiReportStatusFromApi(statusRaw);
    final List<ReportListItem> updated = List<ReportListItem>.from(
      state.reports,
    )..[idx] = state.reports[idx].copyWith(status: next, isOptimistic: false);
    state = state.copyWith(reports: updated);
  }

  bool get hasOptimisticRows =>
      state.reports.any((ReportListItem r) => r.isOptimistic);

  /// Merges a fresh first page with optimistic rows not yet returned by the server.
  static List<ReportListItem> mergeFirstPageWithOptimistic({
    required List<ReportListItem> serverPage,
    required List<ReportListItem> current,
  }) {
    final Set<String> serverIds = serverPage
        .map((ReportListItem r) => r.id)
        .toSet();
    final List<ReportListItem> pendingOptimistic = current
        .where((ReportListItem r) => r.isOptimistic && !serverIds.contains(r.id))
        .toList();
    return <ReportListItem>[...pendingOptimistic, ...serverPage];
  }
}
