import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/domain/models/event_analytics.dart';

/// Fetches event analytics from `GET /events/:id/analytics`.
class ApiEventAnalyticsRepository {
  const ApiEventAnalyticsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Fetches analytics for [eventId].
  ///
  /// Throws [AppError] with code `NOT_AUTHORISED` when the caller is not the organizer.
  Future<EventAnalytics> fetchAnalytics(String eventId) async {
    final ApiResponse response = await _client.get('/events/$eventId/analytics');
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return EventAnalytics.fromJson(json);
  }
}
