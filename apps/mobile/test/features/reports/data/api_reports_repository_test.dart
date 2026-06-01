import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_reports/src/data/api_reports_repository.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/models/reports_list_response.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: () {},
      );

  final List<String> getPaths = <String>[];
  final List<String> postPaths = <String>[];
  final List<Object?> postBodies = <Object?>[];
  final List<Map<String, String>?> postHeaders = <Map<String, String>?>[];
  final Map<String, ApiResponse> _getResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _postResponses = <String, ApiResponse>{};

  void stubGet(String path, Map<String, dynamic> json) {
    _getResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  void stubPost(String path, Map<String, dynamic> json, {int status = 200}) {
    _postResponses[path] = ApiResponse(statusCode: status, json: json);
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    getPaths.add(path);
    final ApiResponse? response = _getResponses[path];
    if (response == null) {
      throw StateError('missing GET stub: $path');
    }
    return response;
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    postPaths.add(path);
    postBodies.add(body);
    postHeaders.add(headers);
    final ApiResponse? response = _postResponses[path];
    if (response == null) {
      throw StateError('missing POST stub: $path');
    }
    return response;
  }
}

void main() {
  late _FakeApiClient client;
  late ApiReportsRepository repo;

  setUp(() {
    client = _FakeApiClient();
    repo = ApiReportsRepository(client: client);
  });

  test('submitReport POSTs body and parses result', () async {
    client.stubPost('/reports', <String, dynamic>{
      'reportId': 'r-new',
      'reportNumber': 'MK-001',
      'siteId': 'site-1',
      'isNewSite': true,
      'pointsAwarded': 40,
      'pointsBreakdown': <dynamic>[
        <String, dynamic>{'code': 'base', 'points': 30},
        <String, dynamic>{'code': 'photo', 'points': 10},
      ],
    });

    final ReportSubmitResult result = await repo.submitReport(
      latitude: 41.99,
      longitude: 21.43,
      title: 'Illegal dump',
      description: 'Near river',
      mediaUrls: <String>['https://cdn.example/a.jpg'],
      category: 'illegalDump',
      severity: 4,
      address: ' Skopje ',
      cleanupEffort: 'medium',
      idempotencyKey: ' key-1 ',
    );

    expect(result.reportId, 'r-new');
    expect(result.isNewSite, isTrue);
    expect(result.pointsAwarded, 40);
    expect(result.pointsBreakdown, hasLength(2));
    expect(client.postHeaders.single?['Idempotency-Key'], 'key-1');
    final Map<String, dynamic> body =
        client.postBodies.single! as Map<String, dynamic>;
    expect(body['address'], 'Skopje');
    expect(body['severity'], 4);
  });

  test('submitReport throws when reportId missing', () async {
    client.stubPost('/reports', <String, dynamic>{'siteId': 's1'});

    await expectLater(
      repo.submitReport(latitude: 1, longitude: 2, title: 'T'),
      throwsA(isA<AppError>()),
    );
  });

  test('getMyReports parses list response', () async {
    client.stubGet('/reports/me?page=1&limit=20', <String, dynamic>{
      'data': <dynamic>[
        <String, dynamic>{
          'id': 'r1',
          'title': 'Report one',
          'status': 'SUBMITTED',
          'submittedAt': '2026-05-01T10:00:00.000Z',
          'location': 'Skopje',
        },
      ],
      'total': 1,
      'page': 1,
      'limit': 20,
    });

    final ReportsListResponse response = await repo.getMyReports();

    expect(response.data, hasLength(1));
    expect(response.data.single, isA<ReportListItem>());
    expect(response.total, 1);
  });

  test('getReportById parses detail payload', () async {
    client.stubGet('/reports/r1', <String, dynamic>{
      'data': <String, dynamic>{
        'id': 'r1',
        'title': 'Detail',
        'status': 'SUBMITTED',
        'submittedAt': '2026-05-01T10:00:00.000Z',
        'location': 'Skopje',
        'description': 'Body',
        'mediaUrls': <String>[],
      },
    });

    final ReportDetail detail = await repo.getReportById('r1');

    expect(detail.id, 'r1');
    expect(detail.title, 'Detail');
  });

  test('getReportingCapacity parses capacity fields', () async {
    client.stubGet('/reports/capacity', <String, dynamic>{
      'creditsAvailable': 2,
      'emergencyAvailable': true,
      'emergencyWindowDays': 14,
      'retryAfterSeconds': 30,
      'nextEmergencyReportAvailableAt': '2026-06-01T00:00:00.000Z',
      'nextRefillAtMs': 1234567890,
      'unlockHint': 'Join an event',
    });

    final ReportCapacity capacity = await repo.getReportingCapacity();

    expect(capacity.creditsAvailable, 2);
    expect(capacity.emergencyAvailable, isTrue);
    expect(capacity.emergencyWindowDays, 14);
    expect(capacity.retryAfterSeconds, 30);
    expect(capacity.nextEmergencyReportAvailableAt, isNotNull);
    expect(capacity.nextRefillAtMs, 1234567890);
    expect(capacity.unlockHint, 'Join an event');
  });

  test('uploadPhotos returns empty outcome for empty paths', () async {
    final outcome = await repo.uploadPhotos(<String>[]);
    expect(outcome.urls, isEmpty);
    expect(client.postPaths, isEmpty);
  });
}
