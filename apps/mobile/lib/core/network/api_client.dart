import 'dart:async';
import 'dart:convert';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:http/http.dart' as http;

/// HTTP client for Chisto API. Attaches base URL, auth token, maps errors to
/// [AppError], and transparently retries once on 401 after refreshing the
/// session (if a [refreshSession] callback is provided).
class ApiClient {
  ApiClient({
    required AppConfig config,
    required String? Function() accessToken,
    required void Function() onUnauthorized,
  })  : _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
        _accessToken = accessToken,
        _onUnauthorized = onUnauthorized;

  final String _baseUrl;
  final String? Function() _accessToken;
  final void Function() _onUnauthorized;

  Future<bool> Function()? refreshSession;

  bool _refreshing = false;

  static const Duration _timeout = Duration(seconds: 30);

  Future<ApiResponse> get(String path, {Map<String, String>? headers}) async {
    return _requestWithRetry('GET', path, headers: headers);
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

  Future<ApiResponse> delete(String path, {Map<String, String>? headers}) async {
    return _requestWithRetry('DELETE', path, headers: headers);
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
    '/auth/password-reset/confirm',
  };

  Future<ApiResponse> _requestWithRetry(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      return await _request(method, path, headers: headers, body: body);
    } on AppError catch (e) {
      if (e.code != 'UNAUTHORIZED' ||
          _authPaths.contains(path) ||
          refreshSession == null ||
          _refreshing) {
        rethrow;
      }

      _refreshing = true;
      try {
        final bool refreshed = await refreshSession!();
        if (!refreshed) rethrow;
      } on Exception catch (_) {
        rethrow;
      } finally {
        _refreshing = false;
      }

      return _request(method, path, headers: headers, body: body);
    }
  }

  Future<ApiResponse> _request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
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
          request = http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          request = http.post(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
          break;
        case 'PATCH':
          request = http.patch(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
          break;
        case 'DELETE':
          request = http.delete(url, headers: requestHeaders);
          break;
        default:
          request = http.post(
            url,
            headers: requestHeaders,
            body: bodyStr,
          );
      }
      final http.Response response = await request.timeout(_timeout);
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

  ApiResponse _handleResponse(http.Response response) {
    final String? bodyStr = response.body.isNotEmpty ? response.body : null;
    Map<String, dynamic>? json;
    if (bodyStr != null) {
      try {
        final Object? decoded = jsonDecode(bodyStr);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        // Not JSON
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        statusCode: response.statusCode,
        body: bodyStr,
        json: json,
      );
    }

    final AppError error = _errorFromResponse(response.statusCode, json, bodyStr);
    throw error;
  }

  AppError _errorFromResponse(
    int statusCode,
    Map<String, dynamic>? json,
    String? bodyStr,
  ) {
    final String code = json?['code'] is String
        ? json!['code'] as String
        : _codeForStatus(statusCode);
    final String message = json?['message'] is String
        ? json!['message'] as String
        : (bodyStr ?? 'Request failed');
    final dynamic details = json?['details'];

    if (statusCode == 401) {
      final String authCode = code;
      // ACCOUNT_NOT_ACTIVE = soft-deleted/suspended; sign out like other auth failures
      if (authCode == 'UNAUTHORIZED' ||
          authCode == 'INVALID_TOKEN_USER' ||
          authCode == 'ACCOUNT_NOT_ACTIVE') {
        _onUnauthorized();
        return AppError(code: authCode, message: message);
      }
      return AppError(code: authCode, message: message);
    }
    if (statusCode == 403) return AppError.forbidden(message: message);
    if (statusCode == 404) return AppError.notFound(message: message);
    if (statusCode == 422 || code == 'VALIDATION_ERROR') {
      return AppError.validation(message: message, details: details);
    }
    if (statusCode >= 500) {
      return AppError.server(message: message);
    }
    if (statusCode == 408 || statusCode == 504) {
      return AppError.timeout(message: message);
    }
    return AppError(
      code: code,
      message: message,
      retryable: statusCode >= 500 || statusCode == 408 || statusCode == 504,
      details: details,
    );
  }

  static String _codeForStatus(int status) {
    switch (status) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 409:
        return 'CONFLICT';
      default:
        return 'HTTP_ERROR';
    }
  }
}

/// Successful API response with optional JSON body.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    this.body,
    this.json,
  });

  final int statusCode;
  final String? body;
  final Map<String, dynamic>? json;
}
