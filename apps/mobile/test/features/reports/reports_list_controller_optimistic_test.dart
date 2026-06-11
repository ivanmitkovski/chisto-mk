import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/domain/models/report_photo_upload_outcome.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/models/reports_list_response.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:feature_reports/src/presentation/controllers/reports_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReportsApiRepository implements ReportsApiRepository {
  @override
  Future<ReportPhotoUploadOutcome> uploadPhotos(List<String> filePaths) async =>
      const ReportPhotoUploadOutcome(urls: <String>[]);

  @override
  Future<void> uploadReportMedia(
    String reportId,
    List<String> filePaths,
  ) async {}

  @override
  Future<ReportSubmitResult> submitReport({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
    String? address,
    String? cleanupEffort,
    String? idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReportsListResponse> getMyReports({
    int page = 1,
    int limit = 20,
    RequestCancellationToken? cancellation,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReportDetail> getReportById(
    String id, {
    RequestCancellationToken? cancellation,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReportCapacity> getReportingCapacity() async {
    throw UnimplementedError();
  }
}

void main() {
  test(
    'insertOptimisticFromSubmit prepends and clearOptimisticForReport clears flag',
    () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          reportsApiRepositoryProvider.overrideWithValue(
            _FakeReportsApiRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final ReportsListController c = container.read(
        reportsListControllerProvider.notifier,
      );
      c.state = c.state.copyWith(
        reports: <ReportListItem>[
          ReportListItem(
            id: 'existing',
            reportNumber: 'R-1',
            title: 'Old',
            location: 'Skopje',
            submittedAt: DateTime.utc(2024, 1, 1),
            status: ApiReportStatus.approved,
            isPotentialDuplicate: false,
            coReporterCount: 0,
          ),
        ],
        isLoadingFirstPage: false,
      );

      final ReportDraft draft = ReportDraft(
        category: ReportCategory.other,
        title: 'Hello',
        description: 'D',
        address: 'Addr',
        cleanupEffort: CleanupEffort.notSure,
        severity: 3,
      );

      const ReportSubmitResult result = ReportSubmitResult(
        reportId: 'new-id',
        reportNumber: 'R-99',
        siteId: 'site',
        isNewSite: false,
        pointsAwarded: 12,
        submittedMediaUrls: <String>['https://example.com/a.jpg'],
      );

      c.insertOptimisticFromSubmit(result, 'Hello', draft);
      expect(c.reports.first.id, 'new-id');
      expect(c.reports.first.isOptimistic, isTrue);
      expect(c.reports.first.mediaUrls, <String>['https://example.com/a.jpg']);

      c.clearOptimisticForReport('new-id');
      expect(c.reports.first.isOptimistic, isFalse);
    },
  );

  test('mergeFirstPageWithOptimistic drops reconciled rows and keeps pending', () {
    final ReportListItem optimistic = ReportListItem(
      id: 'pending-id',
      reportNumber: 'R-pending',
      title: 'Pending',
      location: 'Skopje',
      submittedAt: DateTime.utc(2024, 2, 1),
      status: ApiReportStatus.new_,
      isPotentialDuplicate: false,
      coReporterCount: 0,
      isOptimistic: true,
    );
    final ReportListItem serverRow = ReportListItem(
      id: 'server-id',
      reportNumber: 'R-1',
      title: 'Server',
      location: 'Skopje',
      submittedAt: DateTime.utc(2024, 1, 1),
      status: ApiReportStatus.approved,
      isPotentialDuplicate: false,
      coReporterCount: 0,
    );
    final ReportListItem reconciledOptimistic = ReportListItem(
      id: 'server-id',
      reportNumber: 'R-opt',
      title: 'Optimistic duplicate',
      location: 'Skopje',
      submittedAt: DateTime.utc(2024, 1, 2),
      status: ApiReportStatus.new_,
      isPotentialDuplicate: false,
      coReporterCount: 0,
      isOptimistic: true,
    );

    final List<ReportListItem> merged =
        ReportsListController.mergeFirstPageWithOptimistic(
          serverPage: <ReportListItem>[serverRow],
          current: <ReportListItem>[optimistic, reconciledOptimistic],
        );

    expect(merged.length, 2);
    expect(merged.first.id, 'pending-id');
    expect(merged.first.isOptimistic, isTrue);
    expect(merged.last.id, 'server-id');
    expect(merged.last.isOptimistic, isFalse);
  });
}
