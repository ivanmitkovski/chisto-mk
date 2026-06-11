import 'dart:io';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_reports/src/data/report_detail_cache.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_open_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubReportsApiRepository implements ReportsApiRepository {
  _StubReportsApiRepository({required this.getReportByIdImpl});

  final Future<ReportDetail> Function(String id) getReportByIdImpl;

  @override
  Future<ReportDetail> getReportById(String id, {cancellation}) =>
      getReportByIdImpl(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReportDetail _sampleDetail({String id = 'rep-1'}) {
  return ReportDetail(
    id: id,
    reportNumber: 'R-001',
    status: ApiReportStatus.inReview,
    title: 'River litter',
    description: 'Plastic bottles',
    mediaUrls: const <String>[],
    submittedAt: DateTime.utc(2026, 3, 15),
    site: const ReportDetailSite(
      id: 'site-9',
      latitude: 41.99,
      longitude: 21.42,
    ),
    location: 'Skopje',
  );
}

ReportListItem _sampleListItem({String id = 'rep-1'}) {
  return ReportListItem(
    id: id,
    reportNumber: 'R-001',
    title: 'River litter',
    location: 'Skopje',
    submittedAt: DateTime.utc(2026, 3, 15),
    status: ApiReportStatus.inReview,
    isPotentialDuplicate: false,
    coReporterCount: 0,
  );
}

void main() {
  group('resolveReportDetailForOpen', () {
    test('returns fresh detail and caches on success', () async {
      final ReportDetailCacheStore cache = ReportDetailCacheStore();
      final ReportDetail detail = _sampleDetail();
      final _StubReportsApiRepository repo = _StubReportsApiRepository(
        getReportByIdImpl: (_) async => detail,
      );

      final ReportDetailOpenResolution resolution =
          await resolveReportDetailForOpen(
            repository: repo,
            cache: cache,
            reportId: 'rep-1',
          );

      expect(resolution, isA<ReportDetailOpenFresh>());
      expect((resolution as ReportDetailOpenFresh).detail, detail);
      expect(cache.get('rep-1'), detail);
    });

    test('falls back to cached detail on network error', () async {
      final ReportDetailCacheStore cache = ReportDetailCacheStore();
      cache.put(_sampleDetail());
      final _StubReportsApiRepository repo = _StubReportsApiRepository(
        getReportByIdImpl: (_) => throw AppError.network(
          message: "Failed host lookup: 'api.chisto.mk'",
          cause: const SocketException('Failed host lookup'),
        ),
      );

      final ReportDetailOpenResolution resolution =
          await resolveReportDetailForOpen(
            repository: repo,
            cache: cache,
            reportId: 'rep-1',
          );

      expect(resolution, isA<ReportDetailOpenStaleFallback>());
      final ReportDetailOpenStaleFallback stale =
          resolution as ReportDetailOpenStaleFallback;
      expect(stale.hasDetail, isTrue);
      expect(stale.detail!.id, 'rep-1');
    });

    test('falls back to list item when no detail cache', () async {
      final ReportDetailCacheStore cache = ReportDetailCacheStore();
      final _StubReportsApiRepository repo = _StubReportsApiRepository(
        getReportByIdImpl: (_) => throw AppError.network(),
      );

      final ReportDetailOpenResolution resolution =
          await resolveReportDetailForOpen(
            repository: repo,
            cache: cache,
            reportId: 'rep-1',
            listItem: _sampleListItem(),
          );

      expect(resolution, isA<ReportDetailOpenStaleFallback>());
      final ReportDetailOpenStaleFallback stale =
          resolution as ReportDetailOpenStaleFallback;
      expect(stale.hasListItem, isTrue);
      expect(stale.listItem!.id, 'rep-1');
    });

    test('blocks when no cache and not recoverable', () async {
      final ReportDetailCacheStore cache = ReportDetailCacheStore();
      final _StubReportsApiRepository repo = _StubReportsApiRepository(
        getReportByIdImpl: (_) =>
            throw const AppError(code: 'NOT_FOUND', message: 'missing'),
      );

      final ReportDetailOpenResolution resolution =
          await resolveReportDetailForOpen(
            repository: repo,
            cache: cache,
            reportId: 'rep-1',
          );

      expect(resolution, isA<ReportDetailOpenBlocked>());
    });
  });
}
