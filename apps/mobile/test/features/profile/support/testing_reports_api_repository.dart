import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

/// Minimal [ReportsApiRepository] for profile tests (capacity only).
class TestingReportsApiRepository implements ReportsApiRepository {
  TestingReportsApiRepository({
    Future<ReportCapacity> Function()? getReportingCapacityImpl,
  }) : _getReportingCapacityImpl = getReportingCapacityImpl;

  final Future<ReportCapacity> Function()? _getReportingCapacityImpl;

  @override
  Future<ReportCapacity> getReportingCapacity() {
    final Future<ReportCapacity> Function()? f = _getReportingCapacityImpl;
    if (f == null) {
      throw StateError('getReportingCapacity not stubbed');
    }
    return f();
  }

  @override
  Future<List<String>> uploadPhotos(List<String> filePaths) {
    throw UnimplementedError();
  }

  @override
  Future<void> uploadReportMedia(String reportId, List<String> filePaths) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReportsListResponse> getMyReports({
    int page = 1,
    int limit = 20,
    RequestCancellationToken? cancellation,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReportDetail> getReportById(
    String id, {
    RequestCancellationToken? cancellation,
  }) {
    throw UnimplementedError();
  }
}
