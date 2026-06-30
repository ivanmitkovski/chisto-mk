abstract class FeedAnalyticsRepository {
  Future<void> trackFeedEvent(
    String siteId, {
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  });

  Future<void> submitFeedFeedback(
    String siteId, {
    required String feedbackType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  });
}
