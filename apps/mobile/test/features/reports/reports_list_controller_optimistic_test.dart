import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/reports_list_controller.dart';

class _FakeReportsApiRepository implements ReportsApiRepository {
  @override
  Future<List<String>> uploadPhotos(List<String> filePaths) async => <String>[];

  @override
  Future<void> uploadReportMedia(String reportId, List<String> filePaths) async {}

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
  test('insertOptimisticFromSubmit prepends and clearOptimisticForReport clears flag', () {
    final ReportsListController c = ReportsListController(
      repository: _FakeReportsApiRepository(),
    );
    c.reports = <ReportListItem>[
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
    ];

    final ReportDraft draft = ReportDraft(
      category: ReportCategory.other,
      title: 'Hello',
      description: 'D',
      address: 'Addr',
      cleanupEffort: CleanupEffort.notSure,
      severity: 3,
    );

    final ReportSubmitResult result = ReportSubmitResult(
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
  });
}
