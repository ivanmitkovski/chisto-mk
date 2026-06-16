import 'dart:io';

import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_home/src/data/api_site_resolution_repository.dart';
import 'package:feature_home/src/domain/repositories/site_resolution_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubApiClient extends ApiClient {
  _StubApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  ApiResponse? nextGet;
  ApiResponse? nextPost;
  ApiResponse? nextMultipartPost;
  String? lastPostPath;
  Object? lastPostBody;
  String? lastMultipartPath;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    return nextGet ??
        const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return nextPost ??
        const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }

  @override
  Future<ApiResponse> multipartPostWithRetry(
    String path, {
    required List<MultipartFileData> files,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    lastMultipartPath = path;
    return nextMultipartPost ??
        const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }
}

void main() {
  late _StubApiClient client;
  late ApiSiteResolutionRepository repo;

  setUp(() {
    client = _StubApiClient();
    repo = ApiSiteResolutionRepository(client: client);
  });

  test('uploadResolutionPhotos returns empty list for empty paths', () async {
    final List<String> urls = await repo.uploadResolutionPhotos(
      'site-1',
      <String>[],
    );
    expect(urls, isEmpty);
  });

  test('uploadResolutionPhotos throws when no readable files', () async {
    await expectLater(
      repo.uploadResolutionPhotos(
        'site-1',
        <String>['/tmp/does-not-exist-${DateTime.now().microsecondsSinceEpoch}.jpg'],
      ),
      throwsA(isA<AppError>()),
    );
  });

  test('uploadResolutionPhotos posts multipart and parses urls', () async {
    final Directory dir = Directory.systemTemp.createTempSync(
      'site_resolution_upload_',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final File photo = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(<int>[1, 2, 3]);

    client.nextMultipartPost = const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'data': <String, dynamic>{
          'urls': <String>['https://cdn.example/a.jpg'],
        },
      },
    );

    final List<String> urls = await repo.uploadResolutionPhotos(
      'site-42',
      <String>[photo.path],
    );

    expect(client.lastMultipartPath, '/sites/site-42/resolutions/upload');
    expect(urls, <String>['https://cdn.example/a.jpg']);
  });

  test('submitSiteResolution POSTs trimmed note and parses payload', () async {
    client.nextPost = const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'data': <String, dynamic>{
          'id': 'res-1',
          'siteId': 'site-9',
          'status': 'PENDING',
        },
      },
    );

    final SiteResolutionSubmitResult result = await repo.submitSiteResolution(
      siteId: 'site-9',
      mediaUrls: <String>['https://cdn.example/a.jpg'],
      note: '  cleaned up  ',
    );

    expect(client.lastPostPath, '/sites/site-9/resolutions');
    expect(client.lastPostBody, <String, dynamic>{
      'mediaUrls': <String>['https://cdn.example/a.jpg'],
      'note': 'cleaned up',
    });
    expect(result.id, 'res-1');
    expect(result.siteId, 'site-9');
    expect(result.status, 'PENDING');
  });

  test('submitSiteResolution omits blank note', () async {
    client.nextPost = const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'id': 'res-2',
        'siteId': 'site-10',
        'status': 'APPROVED',
      },
    );

    final SiteResolutionSubmitResult result = await repo.submitSiteResolution(
      siteId: 'site-10',
      mediaUrls: <String>['https://cdn.example/b.jpg'],
      note: '   ',
    );

    expect(client.lastPostBody, <String, dynamic>{
      'mediaUrls': <String>['https://cdn.example/b.jpg'],
    });
    expect(result.id, 'res-2');
    expect(result.status, 'APPROVED');
  });

  test('submitSiteResolution throws when response json is null', () async {
    client.nextPost = const ApiResponse(statusCode: 200);

    await expectLater(
      repo.submitSiteResolution(
        siteId: 'site-11',
        mediaUrls: <String>['https://cdn.example/c.jpg'],
      ),
      throwsA(isA<AppError>()),
    );
  });

  test('getCleanupEvidence maps nested rows and meta', () async {
    client.nextGet = const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 'ev-1',
            'url': 'https://cdn.example/ev.jpg',
            'source': 'RESOLUTION',
            'createdAt': '2026-03-01T10:00:00.000Z',
            'caption': 'After',
            'submitter': <String, dynamic>{'displayLabel': 'Alex'},
            'resolutionId': 'res-9',
            'cleanupEventId': 'evt-1',
          },
        ],
        'meta': <String, dynamic>{'page': 2, 'limit': 12, 'total': 30},
      },
    );

    final CleanupEvidenceListResult result = await repo.getCleanupEvidence(
      'site-7',
      page: 2,
      limit: 12,
    );

    expect(result.items, hasLength(1));
    expect(result.items.first.id, 'ev-1');
    expect(result.items.first.submitterDisplayLabel, 'Alex');
    expect(result.items.first.resolutionId, 'res-9');
    expect(result.page, 2);
    expect(result.limit, 12);
    expect(result.total, 30);
  });

  test('listSiteResolutions maps submitter and media urls', () async {
    client.nextGet = const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 'res-55',
            'siteId': 'site-55',
            'status': 'PENDING',
            'mediaUrls': <String>['https://cdn.example/1.jpg'],
            'createdAt': '2026-04-01T08:00:00.000Z',
            'submitter': <String, dynamic>{'isSelf': true},
            'note': 'Done',
          },
        ],
        'meta': <String, dynamic>{'page': 1, 'limit': 20, 'total': 1},
      },
    );

    final SiteResolutionListResult result = await repo.listSiteResolutions(
      'site-55',
    );

    expect(result.items, hasLength(1));
    expect(result.items.first.id, 'res-55');
    expect(result.items.first.mediaUrls, <String>['https://cdn.example/1.jpg']);
    expect(result.items.first.isSelf, isTrue);
    expect(result.items.first.note, 'Done');
    expect(result.total, 1);
  });
}
