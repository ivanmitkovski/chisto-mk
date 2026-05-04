import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/reports/data/api_reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getReportById passes cancellation token into ApiClient.get', () async {
    final List<Map<String, Object?>> calls = <Map<String, Object?>>[];

    final ApiClient client = _CancellingRecordingApiClient(
      onGet: (String path, {RequestCancellationToken? cancellation}) async {
        calls.add(<String, Object?>{'path': path, 'cancellation': cancellation});
        cancellation?.throwIfCancelled();
        return ApiResponse(statusCode: 200, body: '{}', json: <String, dynamic>{});
      },
    );

    final ApiReportsRepository repo = ApiReportsRepository(client: client);
    final RequestCancellationToken token = RequestCancellationToken();
    token.cancel();

    await expectLater(
      repo.getReportById('r1', cancellation: token),
      throwsA(isA<AppError>().having((AppError e) => e.code, 'code', 'CANCELLED')),
    );

    expect(calls, hasLength(1));
    expect(calls.single['path'], '/reports/r1');
    expect(calls.single['cancellation'], same(token));
  });
}

typedef _GetImpl = Future<ApiResponse> Function(
  String path, {
  RequestCancellationToken? cancellation,
});

class _CancellingRecordingApiClient extends ApiClient {
  _CancellingRecordingApiClient({required this.onGet})
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: () {},
      );

  final _GetImpl onGet;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) {
    return onGet(path, cancellation: cancellation);
  }
}
