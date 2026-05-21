/// Client-side urgency signal for feed filters (API has no `urgencyLabel` field).
///
/// Returns a non-null marker when the site should appear under [FeedFilter.urgent].
String? deriveFeedUrgencyLabel({
  required String? statusCode,
  required DateTime? latestReportAt,
  required int upvotesCount,
  required double? rankingScore,
}) {
  final String status = (statusCode ?? '').toUpperCase();
  if (status == 'REPORTED') {
    return 'needs_attention';
  }
  if (latestReportAt != null) {
    final int days = DateTime.now().difference(latestReportAt).inDays;
    if (days <= 21 && upvotesCount < 8) {
      return 'needs_attention';
    }
  }
  if ((rankingScore ?? 0) >= 120) {
    return 'trending';
  }
  return null;
}
