import 'package:chisto_mobile/features/home/data/feed_urgency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deriveFeedUrgencyLabel marks REPORTED status', () {
    expect(
      deriveFeedUrgencyLabel(
        statusCode: 'REPORTED',
        latestReportAt: null,
        upvotesCount: 0,
        rankingScore: null,
      ),
      'needs_attention',
    );
  });

  test('deriveFeedUrgencyLabel marks recent low-upvote reports', () {
    expect(
      deriveFeedUrgencyLabel(
        statusCode: 'VERIFIED',
        latestReportAt: DateTime.now().subtract(const Duration(days: 3)),
        upvotesCount: 2,
        rankingScore: 10,
      ),
      'needs_attention',
    );
  });

  test('deriveFeedUrgencyLabel returns null for stable verified sites', () {
    expect(
      deriveFeedUrgencyLabel(
        statusCode: 'VERIFIED',
        latestReportAt: DateTime.now().subtract(const Duration(days: 60)),
        upvotesCount: 40,
        rankingScore: 10,
      ),
      isNull,
    );
  });
}
