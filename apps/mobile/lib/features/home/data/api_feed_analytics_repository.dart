import 'dart:async';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';

/// Feed telemetry and feedback HTTP calls (sites API).
class ApiFeedAnalyticsRepository {
  ApiFeedAnalyticsRepository({
    required ApiClient client,
    required Future<void> Function() clearFeedCaches,
  })  : _client = client,
        _clearFeedCaches = clearFeedCaches;

  final ApiClient _client;
  final Future<void> Function() _clearFeedCaches;

  Future<void> trackFeedEvent(
    String siteId, {
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.post(
        '/sites/feed/events',
        body: <String, dynamic>{
          'siteId': siteId,
          'eventType': eventType,
          if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
          ...?metadata?.letMap('metadata'),
        },
      );
    } on AppError {
      // Fire-and-forget feed analytics; callers use unawaited. Ignore failures
      // (logged out, expired token, offline, throttled) so they never surface
      // as unhandled async exceptions.
    }
  }

  Future<void> submitFeedFeedback(
    String siteId, {
    required String feedbackType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.post(
      '/sites/$siteId/feed-feedback',
      body: <String, dynamic>{
        'feedbackType': feedbackType,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        ...?metadata?.letMap('metadata'),
      },
    );
    unawaited(_clearFeedCaches());
  }
}

extension on Map<String, dynamic> {
  Map<String, dynamic> letMap(String key) => <String, dynamic>{key: this};
}
