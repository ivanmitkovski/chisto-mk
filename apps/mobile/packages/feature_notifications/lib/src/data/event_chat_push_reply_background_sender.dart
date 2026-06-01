import 'dart:convert';

import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_events/feature_events.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends event-chat replies from the background notification isolate (no [AppBootstrap]).
abstract final class EventChatPushReplyBackgroundSender {
  static Future<bool> trySend({
    required String eventId,
    required String body,
  }) async {
    final SecureTokenStorage storage = SecureTokenStorage();
    final String? token = await storage.accessToken;
    if (token == null || token.isEmpty) {
      return false;
    }

    final String baseUrl = AppConfig.fromEnvironment().apiBaseUrl.replaceFirst(
      RegExp(r'/$'),
      '',
    );
    final String clientMessageId = newChatClientMessageId();
    final Uri sendUri = Uri.parse('$baseUrl/events/$eventId/chat');

    try {
      final http.Response res = await http
          .post(
            sendUri,
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'body': body,
              'clientMessageId': clientMessageId,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          AppLog.verbose(
            '[Push] background reply HTTP ${res.statusCode} for event $eventId',
          );
        }
        return false;
      }

      final String? messageId = _parseSentMessageId(res.body);
      if (messageId != null && messageId.isNotEmpty) {
        await _patchReadBestEffort(
          baseUrl: baseUrl,
          token: token,
          eventId: eventId,
          messageId: messageId,
        );
      }
      return true;
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] background reply send failed: $e');
      }
      return false;
    }
  }

  static String? _parseSentMessageId(String body) {
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final Object? data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final Object? id = data['id'];
        if (id is String && id.isNotEmpty) {
          return id;
        }
      }
      final Object? id = decoded['id'];
      if (id is String && id.isNotEmpty) {
        return id;
      }
    } on Object {
      return null;
    }
    return null;
  }

  static Future<void> _patchReadBestEffort({
    required String baseUrl,
    required String token,
    required String eventId,
    required String messageId,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/events/$eventId/chat/read');
    try {
      await http
          .patch(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{'lastReadMessageId': messageId}),
          )
          .timeout(const Duration(seconds: 15));
    } on Object {
      // Best-effort only in background isolate.
    }
  }
}
