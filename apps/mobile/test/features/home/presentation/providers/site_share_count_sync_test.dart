import 'package:feature_home/src/presentation/providers/site_engagement_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SiteEngagementState setShareCount updates shareCount field', () {
    final SiteEngagementState initial = SiteEngagementState.initial('site-1');
    expect(initial.shareCount, 0);
    final SiteEngagementState updated = initial.copyWith(shareCount: 4);
    expect(updated.shareCount, 4);
    expect(updated.siteId, 'site-1');
  });
}
