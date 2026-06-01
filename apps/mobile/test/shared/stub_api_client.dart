import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';

/// Default no-op [ApiClient] for unit tests. Override [postForTest] / [getForTest]
/// or subclass with `@override` on [post] / [get] (include [cancellation] param).
class StubApiClient extends ApiClient {
  StubApiClient({
    ApiClientConfig super.config = AppConfig.dev,
    String? Function()? accessToken,
    void Function()? onUnauthorized,
  }) : super(
         accessToken: accessToken ?? (() => null),
         onUnauthorized: onUnauthorized ?? () {},
       );

  String? lastPostPath;
  Object? lastPostBody;
  String? lastGetPath;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) {
    lastGetPath = path;
    return getForTest(path, headers: headers, cancellation: cancellation);
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) {
    lastPostPath = path;
    lastPostBody = body;
    return postForTest(
      path,
      headers: headers,
      body: body,
      cancellation: cancellation,
    );
  }

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    lastPostPath = path;
    lastPostBody = body;
    return patchForTest(path, headers: headers, body: body);
  }

  @override
  Future<ApiResponse> delete(String path, {Map<String, String>? headers}) {
    lastPostPath = path;
    return deleteForTest(path, headers: headers);
  }

  Future<ApiResponse> getForTest(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    return const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }

  Future<ApiResponse> postForTest(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    return const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }

  Future<ApiResponse> patchForTest(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }

  Future<ApiResponse> deleteForTest(
    String path, {
    Map<String, String>? headers,
  }) async {
    return const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }
}
