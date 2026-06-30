import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:chisto_core/chisto_core.dart';

import 'package:chisto_networking/src/api_client_config.dart';
import 'package:chisto_networking/src/network/api_failure_mapper.dart';
import 'package:chisto_networking/src/network/request_cancellation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Optional hook for recording HTTP `Date` headers (wired by app bootstrap).
abstract final class ApiClientHooks {
  static void Function(String? dateHeader)? recordServerDateHeader;
}

/// Ensures REST/SSE clients target the Nest global prefix (`/v1`).
String normalizeApiV1BaseUrl(String raw) {
  final String trimmed = raw.replaceFirst(RegExp(r'/$'), '');
  if (trimmed.endsWith('/v1')) return trimmed;
  return '$trimmed/v1';
}

/// HTTP client for Chisto API. Attaches base URL, auth token, maps errors to
/// [AppError], and transparently retries once on 401 after refreshing the
/// session (if a [refreshSession] callback is provided) for `UNAUTHORIZED` and
/// `SESSION_REVOKED` (rotated / revoked access session on the server).
///
String _normalizeApiV1Base(String raw) => normalizeApiV1BaseUrl(raw);

/// Parallel 401s: one shared refresh [Future]; concurrent callers await it and replay.
class ApiClient {
  ApiClient({
    required ApiClientConfig config,
    required String? Function() accessToken,
    required void Function(int observedEpoch) onUnauthorized,
    int Function()? sessionEpoch,
    String? Function()? acceptLanguageHeader,
    FutureOr<String?> Function()? deviceIdHeader,
    http.Client? httpClient,
  }) : _baseUrl = _normalizeApiV1Base(config.apiBaseUrl),
       _accessToken = accessToken,
       _onUnauthorized = onUnauthorized,
       _sessionEpoch = sessionEpoch ?? (() => 0),
       _acceptLanguageHeader = acceptLanguageHeader,
       _deviceIdHeader = deviceIdHeader,
       _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final String? Function() _accessToken;
  final void Function(int observedEpoch) _onUnauthorized;
  final int Function() _sessionEpoch;
  final String? Function()? _acceptLanguageHeader;
  final FutureOr<String?> Function()? _deviceIdHeader;

  Future<RefreshOutcome> Function()? refreshSession;

  Future<RefreshOutcome>? _refreshInFlight;

  /// Prevents parallel realtime/REST paths from firing [onUnauthorized] repeatedly.
  bool _sessionAuthFailureNotified = false;

  /// Session epoch captured when the current REST/multipart request attached auth.
  int _epochAtRequestSend = 0;

  /// Session epoch captured when the current refresh attempt started.
  int _epochAtRefreshStart = 0;

  final http.Client _httpClient;

  /// Single-flight refresh shared by REST 401 recovery and realtime transports.
  Future<RefreshOutcome> refreshSessionQueued() => _refreshSessionQueued();

  /// Clears the session-teardown guard after a successful login/token save.
  void resetSessionAuthFailureGuard() {
    _sessionAuthFailureNotified = false;
  }

  void notifySessionAuthRejected() {
    final int observedEpoch = _refreshInFlight != null
        ? _epochAtRefreshStart
        : _epochAtRequestSend;
    _notifySessionAuthFailureOnce(observedEpoch);
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
    _epochAtRefreshStart = _sessionEpoch();
    final Future<RefreshOutcome> started = refresh();
    _refreshInFlight = started;
    try {
      return await started;
    } finally {
      if (identical(_refreshInFlight, started)) {
        _refreshInFlight = null;
        _epochAtRefreshStart = 0;
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
  static const int _maxTransientGetRetries = 2;
  static const Duration _transientRetryBase = Duration(milliseconds: 300);

  bool _isTransientGetRetryable(AppError error) {
    if (error.isAuthChallenge) {
      return false;
    }
    switch (error.code) {
      case 'NETWORK_ERROR':
      case 'TIMEOUT':
      case 'SERVER_ERROR':
        return true;
      default:
        return false;
    }
  }

  Duration _transientRetryDelay(int retryIndex) {
    final int ms = _transientRetryBase.inMilliseconds * (1 << retryIndex);
    return Duration(milliseconds: ms);
  }

  Future<T> _withTransientGetRetry<T>(Future<T> Function() request) async {
    var retries = 0;
    while (true) {
      try {
        return await request();
      } on AppError catch (e) {
        if (e.code == 'CANCELLED' ||
            !_isTransientGetRetryable(e) ||
            retries >= _maxTransientGetRetries) {
          rethrow;
        }
        await Future<void>.delayed(_transientRetryDelay(retries));
        retries++;
      }
    }
  }

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

  Future<void> _maybeAddDeviceId(Map<String, String> headers) async {
    final FutureOr<String?> Function()? headerFn = _deviceIdHeader;
    if (headerFn == null ||
        headers.keys.any((String k) => k.toLowerCase() == 'x-device-id')) {
      return;
    }
    final String? value = await headerFn();
    if (value == null || value.trim().isEmpty) return;
    headers['X-Device-Id'] = value.trim();
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    return _withTransientGetRetry(
      () => _requestWithRetry(
        'GET',
        path,
        headers: headers,
        cancellation: cancellation,
      ),
    );
  }

  /// GET binary response (e.g. MVT tiles). Uses [response.bodyBytes] — never
  /// decode as UTF‑16 [String], which would corrupt protobuf payloads.
  Future<ApiBytesResponse> getBytes(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    return _withTransientGetRetry(
      () => _getBytesWithRetry(
        path,
        headers: headers,
        cancellation: cancellation,
      ),
    );
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    return _requestWithRetry(
      'POST',
      path,
      headers: headers,
      body: body,
      cancellation: cancellation,
    );
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

  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _requestWithRetry('DELETE', path, headers: headers);
  }

  /// Multipart file upload. [filePaths] are local paths to files.
  /// Field name is 'files' to match backend FilesInterceptor.
  Future<ApiResponse> postMultipart(String path, List<String> filePaths) async {
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
      final bool mayRecoverWithRefresh = e.isAuthChallenge;
      if (!mayRecoverWithRefresh ||
          _authPaths.contains(path) ||
          refreshSession == null) {
        _notifySessionAuthFailure(e, path);
        rethrow;
      }
      if (!await _refreshForUnauthorizedRetry(e, path)) {
        rethrow;
      }
      return _retryAfterRefresh(path, () => _postMultipart(path, filePaths));
    }
  }

  Future<ApiResponse> _postMultipart(
    String path,
    List<String> filePaths,
  ) async {
    _epochAtRequestSend = _sessionEpoch();
    final Uri url = Uri.parse('$_baseUrl$path');
    final http.MultipartRequest request = http.MultipartRequest('POST', url);

    final String? token = _accessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    _maybeAddAcceptLanguage(request.headers);
    await _maybeAddDeviceId(request.headers);

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
      final http.StreamedResponse streamed = await request.send().timeout(
        _timeout,
      );
      final http.Response response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on TimeoutException catch (e) {
      throw AppError.timeout(
        message: e.message?.isEmpty ?? true ? null : e.message,
      );
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
      if (isCancelled?.call() ?? false) {
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
      final bool mayRecoverWithRefresh = e.isAuthChallenge;
      if (!mayRecoverWithRefresh ||
          _authPaths.contains(path) ||
          refreshSession == null) {
        _notifySessionAuthFailure(e, path);
        rethrow;
      }
      if (!await _refreshForUnauthorizedRetry(e, path)) {
        rethrow;
      }
      return _retryAfterRefresh(
        path,
        () =>
            multipartPost(path, files: files, fields: fields, timeout: timeout),
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
    _epochAtRequestSend = _sessionEpoch();
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

    final int totalBytes = files.fold<int>(
      0,
      (int a, MultipartFileData f) => a + f.bytes.length,
    );
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
      final http.StreamedResponse streamed = await _httpClient
          .send(request)
          .timeout(effectiveTimeout);
      final http.Response response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on TimeoutException catch (e) {
      throw AppError.timeout(
        message: e.message?.isEmpty ?? true ? null : e.message,
      );
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
    _notifySessionAuthFailureOnce(_epochAtRequestSend);
  }

  void _notifySessionAuthFailureOnce(int observedEpoch) {
    if (_sessionAuthFailureNotified) return;
    _sessionAuthFailureNotified = true;
    _onUnauthorized(observedEpoch);
  }

  /// Runs a single post-refresh replay; auth failures still trigger teardown.
  Future<T> _retryAfterRefresh<T>(
    String path,
    Future<T> Function() retry,
  ) async {
    try {
      return await retry();
    } on AppError catch (e) {
      if (e.isAuthChallenge || e.indicatesInvalidOrEndedSession) {
        _notifySessionAuthFailure(e, path);
      }
      rethrow;
    }
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
      final bool mayRecoverWithRefresh = e.isAuthChallenge;
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
      return _retryAfterRefresh(
        path,
        () => _getBytes(path, headers: headers, cancellation: cancellation),
      );
    }
  }

  Future<ApiBytesResponse> _getBytes(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    _epochAtRequestSend = _sessionEpoch();
    final Uri url = Uri.parse('$_baseUrl$path');
    final Map<String, String> requestHeaders = <String, String>{
      'Accept':
          'application/vnd.mapbox-vector-tile, application/octet-stream;q=0.9, */*;q=0.8',
      ...?headers,
    };
    final String? token = _accessToken();
    if (token != null && token.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }
    _maybeAddAcceptLanguage(requestHeaders);
    await _maybeAddDeviceId(requestHeaders);

    try {
      final http.Response response = await _httpClient
          .get(url, headers: requestHeaders)
          .timeout(_timeout);
      cancellation?.throwIfCancelled();
      return _handleBytesResponse(response);
    } on TimeoutException catch (e) {
      throw AppError.timeout(
        message: e.message?.isEmpty ?? true ? null : e.message,
      );
    } on AppError {
      rethrow;
    } on Exception catch (e) {
      throw _networkErrorFromTransportException(e);
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

    final String? bodyStr = response.bodyBytes.isNotEmpty
        ? utf8.decode(response.bodyBytes)
        : null;
    final Map<String, dynamic>? json = bodyStr != null
        ? _decodeJsonObject(bodyStr)
        : null;
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
      final bool mayRecoverWithRefresh = e.isAuthChallenge;
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
      return _retryAfterRefresh(
        path,
        () => _request(
          method,
          path,
          headers: headers,
          body: body,
          cancellation: cancellation,
        ),
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
    _epochAtRequestSend = _sessionEpoch();
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
    await _maybeAddDeviceId(requestHeaders);

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
        case 'POST':
          request = _httpClient.post(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
        case 'PATCH':
          request = _httpClient.patch(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
        case 'PUT':
          request = _httpClient.put(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
        case 'DELETE':
          request = _httpClient.delete(url, headers: requestHeaders);
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
      throw AppError.timeout(
        message: e.message?.isEmpty ?? true ? null : e.message,
      );
    } on AppError {
      rethrow;
    } on Exception catch (e) {
      throw _networkErrorFromTransportException(e);
    }
  }

  /// Maps low-level socket/TLS failures to [AppError.network] instead of
  /// rethrowing (which becomes [AppError.unknown] upstream and hides the cause).
  static Never _networkErrorFromTransportException(Object e) {
    final String raw = switch (e) {
      SocketException(:final String message) => message,
      HandshakeException(:final String message) => message,
      TlsException(:final String message) => message,
      http.ClientException(:final String message) => message,
      _ => e.toString(),
    };
    final String lower = raw.toLowerCase();
    final String message =
        lower.contains('cleartext') || raw.contains('Cleartext HTTP')
        ? 'Connection blocked (cleartext). Rebuild the app after pulling the latest Android network config.'
        : (raw.isNotEmpty ? raw : 'Unable to reach the server.');
    throw AppError.network(message: message, cause: e);
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
    ApiClientHooks.recordServerDateHeader?.call(date);
  }

  ApiResponse _handleResponse(http.Response response) {
    _recordServerClock(response.headers);
    final String? bodyStr = response.body.isNotEmpty ? response.body : null;
    final Map<String, dynamic>? json = bodyStr != null
        ? _decodeJsonObject(bodyStr)
        : null;

    if ((response.statusCode >= 200 && response.statusCode < 300) ||
        response.statusCode == 304) {
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
