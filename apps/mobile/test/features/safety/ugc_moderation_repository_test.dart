import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => 'token',
        onUnauthorized: () {},
      );

  final List<(String method, String path, Object? body)> calls =
      <(String, String, Object?)>[];

  String blocksBody = '[]';

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    calls.add(('post', path, body));
    return const ApiResponse(
      statusCode: 201,
      json: <String, dynamic>{'id': 'r1'},
    );
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    calls.add(('get', path, null));
    return ApiResponse(statusCode: 200, body: blocksBody);
  }

  @override
  Future<ApiResponse> delete(
    String path, {
    Object? body,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    calls.add(('delete', path, body));
    return const ApiResponse(statusCode: 204);
  }
}

void main() {
  late _RecordingApiClient client;
  late UgcModerationRepository repo;

  setUp(() {
    client = _RecordingApiClient();
    repo = UgcModerationRepository(client: client);
  });

  test('submitReport posts moderation payload with trimmed details', () async {
    await repo.submitReport(
      subjectType: 'user',
      subjectId: 'u-peer',
      reason: 'harassment',
      details: '  details  ',
    );

    expect(client.calls, hasLength(1));
    expect(client.calls.single.$1, 'post');
    expect(client.calls.single.$2, '/moderation/reports');
    expect(client.calls.single.$3, <String, dynamic>{
      'subjectType': 'user',
      'subjectId': 'u-peer',
      'reason': 'harassment',
      'details': 'details',
    });
  });

  test('submitReport omits empty details', () async {
    await repo.submitReport(
      subjectType: 'safety_issue',
      subjectId: 'u-self',
      reason: 'other',
      details: '   ',
    );

    expect(client.calls.single.$3, <String, dynamic>{
      'subjectType': 'safety_issue',
      'subjectId': 'u-self',
      'reason': 'other',
    });
  });

  test('blockUser posts blockedUserId', () async {
    await repo.blockUser('u-peer');

    expect(client.calls.single.$2, '/users/me/blocks');
    expect(client.calls.single.$3, <String, dynamic>{
      'blockedUserId': 'u-peer',
    });
  });

  test('listBlocks decodes JSON array body', () async {
    client.blocksBody =
        '[{"blockedUserId":"u-peer","blocked":{"id":"u-peer","firstName":"Peer","lastName":"User"}}]';

    final List<BlockedUserRow> rows = await repo.listBlocks();

    expect(rows, hasLength(1));
    expect(rows.single.blockedUserId, 'u-peer');
    expect(rows.single.displayName, 'Peer User');
  });

  test('listBlocks skips rows without blockedUserId', () async {
    client.blocksBody = '[{"blocked":{"firstName":"Ghost"}}]';

    final List<BlockedUserRow> rows = await repo.listBlocks();

    expect(rows, isEmpty);
  });

  test('unblockUser deletes block by id', () async {
    await repo.unblockUser('u-peer');

    expect(client.calls.single.$1, 'delete');
    expect(client.calls.single.$2, '/users/me/blocks/u-peer');
  });
}
