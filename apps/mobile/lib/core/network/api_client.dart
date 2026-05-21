import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/domain/refresh_outcome.dart';
import 'package:chisto_mobile/core/network/api_failure_mapper.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/core/time/server_clock.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;

/// HTTP client for Chisto API. Attaches base URL, auth token, maps errors to
/// [AppError], and transparently retries once on 401 after refreshing the
/// session (if a [refreshSession] callback is provided) for `UNAUTHORIZED` and
/// `SESSION_REVOKED` (rotated / revoked access session on the server).
///
/// Parallel 401s: one shared refresh [Future]; concurrent callers await it and replay.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required String? Function() accessToken,
    required void Function() onUnauthorized,
    String? Function()? acceptLanguageHeader,
    http.Client? httpClient,
  })  : _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
        _accessToken = accessToken,
        _onUnauthorized = onUnauthorized,
        _acceptLanguageHeader = acceptLanguageHeader,
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final String? Function() _accessToken;
  final void Function() _onUnauthorized;
  final String? Function()? _acceptLanguageHeader;

  Future<RefreshOutcome> Function()? refreshSession;

  Future<RefreshOutcome>? _refreshInFlight;

  /// Prevents parallel realtime/REST paths from firing [onUnauthorized] repeatedly.
  bool _sessionAuthFailureNotified = false;

  final http.Client _httpClient;

  /// Single-flight refresh shared by REST 401 recovery and realtime transports.
  Future<RefreshOutcome> refreshSessionQueued() => _refreshSessionQueued();

  /// Clears the session-teardown guard after a successful login/token save.
  void resetSessionAuthFailureGuard() {
    _sessionAuthFailureNotified = false;
  }

  void notifySessionAuthRejected() {
    _notifySessionAuthFailureOnce();
  }

  Future<RefreshOutcome> _refreshSessionQueued() async {
    final Future<RefreshOutcome> Function()? refresh = refreshSession;
    if (refresh == null) {
      return RefreshOutcome.transient;
    }
    final Future<RefreshOutcome>? inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final Future<RefreshOutcome> started = refresh();
    _refreshInFlight = started;
    try {
      return await started;
    } finally {
      if (identical(_refreshInFlight, started)) {
        _refreshInFlight = null;
      }
    }
  }

  /// Returns true when refresh succeeded and the caller may retry the request.
  Future<bool> _refreshForUnauthorizedRetry(AppError error, String path) async {
    final RefreshOutcome outcome = await _refreshSessionQueued();
    if (outcome == RefreshOutcome.success) {
      return true;
    }
    if (outcome == RefreshOutcome.serverRejected) {
      _notifySessionAuthFailure(error, path);
    }
    return false;
  }

  static const Duration _timeout = Duration(seconds: 30);

  void dispose() {
    _httpClient.close();
  }

  void _maybeAddAcceptLanguage(Map<String, String> headers) {
    final String? Function()? headerFn = _acceptLanguageHeader;
    if (headerFn == null) {
      return;
    }
    const String key = 'Accept-Language';
    if (headers.keys.any((String k) => k.toLowerCase() == key.toLowerCase())) {
      return;
    }
    final String? value = headerFn();
    if (value == null || value.trim().isEmpty) {
      return;
    }
    headers[key] = value.trim();
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    return _requestWithRetry(
      'GET',
      path,
      headers: headers,
      cancellation: cancellation,
    );
  }

  /// GET binary response (e.g. MVT tiles). Uses [response.bodyBytes] — never
  /// decode as UTF‑16 [String], which would corrupt protobuf payloads.
  Future<ApiBytesResponse> getBytes(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    return _getBytesWithRetry(
      path,
      headers: headers,
      cancellation: cancellation,
    );
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _requestWithRetry('POST', path, headers: headers, body: body);
  }

  Future<ApiResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _requestWithRetry('PATCH', path, headers: headers, body: body);
  }

  Future<ApiResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _requestWithRetry('PUT', path, headers: headers, body: body);
  }

  Future<ApiResponse> delete(String path, {Map<String, String>? headers}) async {
    return _requestWithRetry('DELETE', path, headers: headers);
  }

  /// Multipart file upload. [filePaths] are local paths to files.
  /// Field name is 'files' to match backend FilesInterceptor.
  Future<ApiResponse> postMultipart(
    String path,
    List<String> filePaths,
  ) async {
    return _postMultipartWithRetry(path, filePaths);
  }

  Future<ApiResponse> _postMultipartWithRetry(
    String path,
    List<String> filePaths,
  ) async {
    try {
      return await _postMultipart(path, filePaths);
    } on AppError catch (e) {
      if (e.code == 'CANCELLED') {
        rethrow;
      }
      final bool mayRecoverWithRefresh = e.code == 'UNAUTHORIZED' ||
          e.code == 'SESSION_REVOKED';
      if (!mayRecoverWithRefresh ||
          _authPaths.contains(path) ||
          refreshSession == null) {
        _notifySessionAuthFailure(e, path);
        rethrow;
      }
      if (!await _refreshForUnauthorizedRetry(e, path)) {
        rethrow;
      }
      return await _postMultipart(path, filePaths);
    }
  }

  Future<ApiResponse> _postMultipart(
    String path,
    List<String> filePaths,
  ) async {
    final Uri url = Uri.parse('$_baseUrl$path');
    final http.MultipartRequest request =
        http.MultipartRequest('POST', url);

    final String? token = _accessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    _maybeAddAcceptLanguage(request.headers);

    for (final String filePath in filePaths) {
      final MediaType? contentType = _contentTypeForPath(filePath);
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          filePath,
          contentType: contentType,
        ),
      );
    }

    try {
      final http.StreamedResponse streamed =
          await request.send().timeout(_timeout);
      final http.Response response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on TimeoutException catch (e) {
      throw AppError.timeout(
          message: e.message?.isEmpty ?? true ? null : e.message);
    } on SocketException catch (e) {
      throw AppError.network(message: e.message, cause: e);
    } on AppError {
      rethrow;
    } on Exception catch (e) {
      if (e is http.ClientException) {
        throw AppError.network(message: e.message, cause: e);
      }
      rethrow;
    }
  }

  Stream<List<int>> _chunkedByteStream(
    List<int> bytes, {
    required void Function(int chunkLength) onChunk,
    bool Function()? isCancelled,
  }) async* {
    const int chunkSize = 64 * 1024;
    int offset = 0;
    while (offset < bytes.length) {
      if (isCancelled?.call() == true) {
        throw AppError.cancelled(message: 'Upload cancelled');
      }
      final int end = min(offset + chunkSize, bytes.length);
      final List<int> slice = bytes.sublist(offset, end);
      yield slice;
      onChunk(slice.length);
      offset = end;
    }
  }

  Future<ApiResponse> multipartPostWithRetry(
    String path, {
    required List<MultipartFileData> files,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    try {
      return await multipartPost(
        path,
        files: files,
        fields: fields,
        timeout: timeout,
      );
    } on AppError catch (e) {
      final bool mayRecoverWithRefresh = e.code == 'UNAUTHORIZED' ||
          e.code == 'SESSION_REVOKED';
      if (!mayRecoverWithRefresh ||
          _authPaths.contains(path) ||
          refreshSession == null) {
        rethrow;
      }
      if (await _refreshSessionQueued() != RefreshOutcome.success) {
        rethrow;
      }
      return await multipartPost(
        path,
        files: files,
        fields: fields,
        timeout: timeout,
      );
    }
  }

  Future<ApiResponse> multipartPost(
    String path, {
    required List<MultipartFileData> files,
    Map<String, String>? fields,
    void Function(int sent, int total)? onSendProgress,
    bool Function()? isCancelled,
    Duration? timeout,
  }) async {
    final Uri url = Uri.parse('$_baseUrl$path');
    final http.MultipartRequest request = http.MultipartRequest('POST', url);

    final String? token = _accessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    _maybeAddAcceptLanguage(request.headers);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final int totalBytes =
        files.fold<int>(0, (int a, MultipartFileData f) => a + f.bytes.length);
    int sentTotal = 0;
    for (final MultipartFileData f in files) {
      final int fileLen = f.bytes.length;
      final Stream<List<int>> stream = _chunkedByteStream(
        f.bytes,
        onChunk: (int n) {
          sentTotal += n;
          onSendProgress?.call(sentTotal, totalBytes);
        },
        isCancelled: isCancelled,
      );
      request.files.add(
        http.MultipartFile(
          f.field,
          http.ByteStream(stream),
          fileLen,
          filename: f.fileName,
          contentType: MediaType.parse(f.mimeType),
        ),
      );
    }

    try {
      final Duration effectiveTimeout = timeout ?? _timeout;
      final http.StreamedResponse streamed =
          await request.send().timeout(effectiveTimeout);
      final http.Response response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on TimeoutException catch (e) {
      throw AppError.timeout(
          message: e.message?.isEmpty ?? true ? null : e.message);
    } on SocketException catch (e) {
      throw AppError.network(message: e.message, cause: e);
    } on AppError {
      rethrow;
    } on Exception catch (e) {
      if (e is http.ClientException) {
        throw AppError.network(message: e.message, cause: e);
      }
      rethrow;
    }
  }

  static MediaType? _contentTypeForPath(String path) {
    final String name = path.split(RegExp(r'[/\\]')).last.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  /// Auth-related paths that should never trigger a transparent refresh
  /// (they manage tokens themselves).
  static const Set<String> _authPaths = <String>{
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/logout',
    '/auth/otp/send',
    '/auth/otp/verify',
    '/auth/password-reset/request',
    '/auth/password-reset/verify-code',
    '/auth/password-reset/confirm',
  };

  /// Best-effort teardown: 401 here must not cascade into [onUnauthorized].
  static const Set<String> _pathsExemptFromUnauthorizedCallback = <String>{
    '/notifications/devices/unregister',
  };

  void _notifySessionAuthFailure(AppError error, String path) {
    if (!error.indicatesInvalidOrEndedSession) return;
    if (_authPaths.contains(path)) return;
    if (_pathsExemptFromUnauthorizedCallback.contains(path)) return;
    _notifySessionAuthFailureOnce();
  }

  void _notifySessionAuthFailureOnce() {
    if (_sessionAuthFailureNotified) return;
    _sessionAuthFailureNotified = true;
    _onUnauthorized();
  }

  Future<ApiBytesResponse> _getBytesWithRetry(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    try {
      return await _getBytes(
        path,
        headers: headers,
        cancellation: cancellation,
      );
    } on AppError catch (e) {
      if (e.code == 'CANCELLED') {
        rethrow;
      }
      final bool mayRecoverWithRefresh = e.code == 'UNAUTHORIZED' ||
          e.code == 'SESSION_REVOKED';
      if (!mayRecoverWithRefresh ||
          _authPaths.contains(path) ||
          refreshSession == null) {
        _notifySessionAuthFailure(e, path);
        rethrow;
      }
      if (!await _refreshForUnauthorizedRetry(e, path)) {
        rethrow;
      }

      cancellation?.throwIfCancelled();
      return await _getBytes(
        path,
        headers: headers,
        cancellation: cancellation,
      );
    }
  }

  Future<ApiBytesResponse> _getBytes(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final Uri url = Uri.parse('$_baseUrl$path');
    final Map<String, String> requestHeaders = <String, String>{
      'Accept': 'application/vnd.mapbox-vector-tile, application/octet-stream;q=0.9, */*;q=0.8',
      ...?headers,
    };
    final String? token = _accessToken();
    if (token != null && token.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    _maybeAddAcceptLanguage(requestHeaders);

    try {
      final http.Response response =
          await _httpClient.get(url, headers: requestHeaders).timeout(_timeout);
      cancellation?.throwIfCancelled();
      return _handleBytesResponse(response);
    } on TimeoutException catch (e) {
      throw AppError.timeout(message: e.message?.isEmpty ?? true ? null : e.message);
    } on AppError {
      rethrow;
    } on Exception catch (e) {
      if (e is http.ClientException) {
        throw AppError.network(message: e.message, cause: e);
      }
      rethrow;
    }
  }

  ApiBytesResponse _handleBytesResponse(http.Response response) {
    _recordServerClock(response.headers);
    final Uint8List bytes = Uint8List.fromList(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiBytesResponse(
        statusCode: response.statusCode,
        bytes: bytes,
        headers: response.headers,
      );
    }
    if (response.statusCode == 304) {
      return ApiBytesResponse(
        statusCode: response.statusCode,
        bytes: bytes,
        headers: response.headers,
      );
    }

    final String? bodyStr =
        response.bodyBytes.isNotEmpty ? utf8.decode(response.bodyBytes) : null;
    final Map<String, dynamic>? json =
        bodyStr != null ? _decodeJsonObject(bodyStr) : null;
    final String? retryAfterHeader = response.headers['retry-after'];
    final AppError error = appErrorFromFailedResponse(
      statusCode: response.statusCode,
      json: json,
      bodyStr: bodyStr,
      retryAfterHeader: retryAfterHeader,
    );

    throw error;
  }

  Future<ApiResponse> _requestWithRetry(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    try {
      return await _request(
        method,
        path,
        headers: headers,
        body: body,
        cancellation: cancellation,
      );
    } on AppError catch (e) {
      if (e.code == 'CANCELLED') {
        rethrow;
      }
      final bool mayRecoverWithRefresh = e.code == 'UNAUTHORIZED' ||
          e.code == 'SESSION_REVOKED';
      if (!mayRecoverWithRefresh ||
          _authPaths.contains(path) ||
          refreshSession == null) {
        _notifySessionAuthFailure(e, path);
        rethrow;
      }
      if (!await _refreshForUnauthorizedRetry(e, path)) {
        rethrow;
      }

      cancellation?.throwIfCancelled();
      return await _request(
        method,
        path,
        headers: headers,
        body: body,
        cancellation: cancellation,
      );
    }
  }

  Future<ApiResponse> _request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final Uri url = Uri.parse('$_baseUrl$path');
    final Map<String, String> requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };
    final String? token = _accessToken();
    if (token != null && token.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    _maybeAddAcceptLanguage(requestHeaders);

    String? bodyStr;
    if (body != null) {
      if (body is Map<String, dynamic>) {
        bodyStr = jsonEncode(body);
      } else if (body is String) {
        bodyStr = body;
      } else {
        bodyStr = jsonEncode(body);
      }
    }

    try {
      final Future<http.Response> request;
      switch (method) {
        case 'GET':
          request = _httpClient.get(url, headers: requestHeaders);
          break;
        case 'POST':
          request = _httpClient.post(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
          break;
        case 'PATCH':
          request = _httpClient.patch(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
          break;
        case 'PUT':
          request = _httpClient.put(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
          break;
        case 'DELETE':
          request = _httpClient.delete(url, headers: requestHeaders);
          break;
        default:
          request = _httpClient.post(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
      }
      final http.Response response = await request.timeout(_timeout);
      cancellation?.throwIfCancelled();
      return _handleResponse(response);
    } on TimeoutException catch (e) {
      throw AppError.timeout(message: e.message?.isEmpty ?? true ? null : e.message);
    } on AppError {
      rethrow;
    } on Exception catch (e) {
      if (e is http.ClientException) {
        throw AppError.network(message: e.message, cause: e);
      }
      rethrow;
    }
  }

  static Map<String, dynamic>? _decodeJsonObject(String bodyStr) {
    try {
      final Object? decoded = jsonDecode(bodyStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Not JSON
    }
    return null;
  }

  void _recordServerClock(Map<String, String> headers) {
    // [http] lowercases header keys; pull either casing to be safe.
    final String? date = headers['date'] ?? headers['Date'];
    if (date != null) {
      ServerClock.instance.recordDateHeader(date);
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    _recordServerClock(response.headers);
    final String? bodyStr = response.body.isNotEmpty ? response.body : null;
    final Map<String, dynamic>? json =
        bodyStr != null ? _decodeJsonObject(bodyStr) : null;

    if ((response.statusCode >= 200 && response.statusCode < 300) || response.statusCode == 304) {
      return ApiResponse(
        statusCode: response.statusCode,
        body: bodyStr,
        json: json,
        headers: response.headers,
      );
    }

    final String? retryAfterHeader = response.headers['retry-after'];
    final AppError error = appErrorFromFailedResponse(
      statusCode: response.statusCode,
      json: json,
      bodyStr: bodyStr,
      retryAfterHeader: retryAfterHeader,
    );

    throw error;
  }
}

/// Binary GET response (tiles, files).
class ApiBytesResponse {
  const ApiBytesResponse({
    required this.statusCode,
    required this.bytes,
    this.headers = const <String, String>{},
  });

  final int statusCode;
  final Uint8List bytes;
  final Map<String, String> headers;
}

/// Successful API response with optional JSON body.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    this.body,
    this.json,
    this.headers = const <String, String>{},
  });

  final int statusCode;
  final String? body;
  final Map<String, dynamic>? json;
  final Map<String, String> headers;
}

/// Represents a single file to include in a multipart upload.
class MultipartFileData {
  const MultipartFileData({
    required this.field,
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final String field;
  final List<int> bytes;
  final String fileName;
  final String mimeType;
}
