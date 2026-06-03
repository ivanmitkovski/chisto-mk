import 'package:feature_reports/src/data/api_reports_mappers.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _listItemFixture() {
  return <String, dynamic>{
    'id': 'rep-1',
    'reportNumber': 'R-001',
    'title': 'River litter',
    'description': 'Plastic bottles near the bank',
    'location': 'Vardar, Skopje',
    'submittedAt': '2026-03-15T10:30:00.000Z',
    'status': 'IN_REVIEW',
    'isPotentialDuplicate': true,
    'coReporterCount': 2,
    'mediaUrls': <dynamic>[
      'https://cdn.example/a.jpg',
      <String, dynamic>{'url': '//cdn.example/b.jpg'},
    ],
    'pointsAwarded': 15,
    'category': 'WATER_POLLUTION',
    'severity': 4,
    'cleanupEffort': 'THREE_TO_FIVE',
    'viewerRole': 'co_reporter',
    'moderationReason': null,
  };
}

Map<String, dynamic> _detailFixture() {
  return <String, dynamic>{
    ..._listItemFixture(),
    'reporterName': 'Alex',
    'coReporterNames': <dynamic>['Sam', 42, 'Jordan'],
    'site': <String, dynamic>{
      'id': 'site-9',
      'latitude': 41.9973,
      'longitude': 21.4280,
      'description': 'River bank',
      'address': 'Skopje',
    },
  };
}

void main() {
  group('reportListItemFromApiJson', () {
    test('maps full fixture JSON', () {
      final ReportListItem item = reportListItemFromApiJson(_listItemFixture());

      expect(item.id, 'rep-1');
      expect(item.reportNumber, 'R-001');
      expect(item.title, 'River litter');
      expect(item.description, 'Plastic bottles near the bank');
      expect(item.location, 'Vardar, Skopje');
      expect(item.submittedAt, DateTime.parse('2026-03-15T10:30:00.000Z'));
      expect(item.status, ApiReportStatus.inReview);
      expect(item.isPotentialDuplicate, isTrue);
      expect(item.coReporterCount, 2);
      expect(item.mediaUrls, <String>[
        'https://cdn.example/a.jpg',
        'https://cdn.example/b.jpg',
      ]);
      expect(item.pointsAwarded, 15);
      expect(item.category, ReportCategory.waterPollution);
      expect(item.severity, 4);
      expect(item.cleanupEffort, CleanupEffort.threeToFive);
      expect(item.viewerRole, ReportViewerRole.coReporter);
      expect(item.moderationReason, isNull);
    });

    test('maps moderationReason for deleted status', () {
      final ReportListItem item = reportListItemFromApiJson(
        <String, dynamic>{
          ..._listItemFixture(),
          'status': 'DELETED',
          'moderationReason':
              'Insufficient evidence. Notes: The evidence is not enough',
        },
      );
      expect(item.status, ApiReportStatus.deleted);
      expect(
        item.moderationReason,
        'Insufficient evidence. Notes: The evidence is not enough',
      );
    });

    test('defaults missing optional fields', () {
      final ReportListItem item = reportListItemFromApiJson(
        <String, dynamic>{},
      );

      expect(item.id, '');
      expect(item.reportNumber, '');
      expect(item.title, '');
      expect(item.description, isNull);
      expect(item.location, '');
      expect(item.status, ApiReportStatus.new_);
      expect(item.isPotentialDuplicate, isFalse);
      expect(item.coReporterCount, 0);
      expect(item.mediaUrls, isEmpty);
      expect(item.pointsAwarded, 0);
      expect(item.category, isNull);
      expect(item.severity, isNull);
      expect(item.cleanupEffort, isNull);
      expect(item.viewerRole, ReportViewerRole.primary);
      expect(item.moderationReason, isNull);
    });
  });

  group('reportDetailFromApiJson', () {
    test('maps site, coReporterNames, and reporter fields', () {
      final ReportDetail detail = reportDetailFromApiJson(_detailFixture());

      expect(detail.id, 'rep-1');
      expect(detail.reportNumber, 'R-001');
      expect(detail.status, ApiReportStatus.inReview);
      expect(detail.title, 'River litter');
      expect(detail.description, 'Plastic bottles near the bank');
      expect(detail.reporterName, 'Alex');
      expect(detail.coReporterNames, <String>['Sam', 'Jordan']);
      expect(detail.location, 'Vardar, Skopje');
      expect(detail.submittedAt, DateTime.parse('2026-03-15T10:30:00.000Z'));
      expect(detail.pointsAwarded, 15);
      expect(detail.category, ReportCategory.waterPollution);
      expect(detail.severity, 4);
      expect(detail.cleanupEffort, CleanupEffort.threeToFive);
      expect(detail.viewerRole, ReportViewerRole.coReporter);
      expect(detail.site.id, 'site-9');
      expect(detail.site.latitude, closeTo(41.9973, 0.0001));
      expect(detail.site.longitude, closeTo(21.4280, 0.0001));
      expect(detail.site.description, 'River bank');
      expect(detail.site.address, 'Skopje');
      expect(detail.mediaUrls, <String>[
        'https://cdn.example/a.jpg',
        'https://cdn.example/b.jpg',
      ]);
      expect(detail.moderationReason, isNull);
    });

    test('maps moderationReason when status is DELETED', () {
      final ReportDetail detail = reportDetailFromApiJson(<String, dynamic>{
        ..._detailFixture(),
        'status': 'DELETED',
        'moderationReason': 'False report. Notes: Duplicate of CH-001',
      });
      expect(detail.status, ApiReportStatus.deleted);
      expect(detail.moderationReason, 'False report. Notes: Duplicate of CH-001');
    });

    test('uses empty site defaults when site is missing', () {
      final ReportDetail detail = reportDetailFromApiJson(<String, dynamic>{
        'id': 'rep-2',
        'title': 'Fallback',
      });

      expect(
        detail.site,
        const ReportDetailSite(id: '', latitude: 0, longitude: 0),
      );
      expect(detail.coReporterNames, isEmpty);
      expect(detail.reporterName, isNull);
    });
  });
}
