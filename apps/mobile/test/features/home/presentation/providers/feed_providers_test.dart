import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/feed_providers.dart';
import 'package:feature_home/src/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/home/feed_status_test_helpers.dart';

void main() {
  test('feedApiParamsForFilter maps discovery scope for default tabs', () {
    expect(feedApiParamsForFilter(FeedFilter.all).scope, 'discovery');
    expect(feedApiParamsForFilter(FeedFilter.recent).scope, 'discovery');
    expect(feedApiParamsForFilter(FeedFilter.mostVoted).scope, 'discovery');
    expect(feedApiParamsForFilter(FeedFilter.all).sort, 'hybrid');
    expect(feedApiParamsForFilter(FeedFilter.all).mode, 'for_you');
    expect(feedApiParamsForFilter(FeedFilter.all).radiusKm, 150.0);
    expect(feedApiParamsForFilter(FeedFilter.recent).sort, 'recent');
    expect(feedApiParamsForFilter(FeedFilter.recent).mode, 'latest');
  });

  test('feedApiParamsForFilter keeps nearby and urgent local', () {
    expect(feedApiParamsForFilter(FeedFilter.nearby).scope, 'local');
    expect(feedApiParamsForFilter(FeedFilter.nearby).radiusKm, 25.0);
    expect(feedApiParamsForFilter(FeedFilter.urgent).scope, 'local');
  });

  test('feedServerFetchGroup treats saved as distinct from hybrid feed', () {
    expect(
      feedServerFetchGroup(FeedFilter.all),
      feedServerFetchGroup(FeedFilter.mostVoted),
    );
    expect(
      feedServerFetchGroup(FeedFilter.saved),
      isNot(feedServerFetchGroup(FeedFilter.all)),
    );
    expect(
      feedServerFetchGroup(FeedFilter.saved),
      isNot(feedServerFetchGroup(FeedFilter.recent)),
    );
  });

  test(
    'feedStatusForLoadedResult returns noLocation when empty and offline',
    () {
      expect(
        feedStatusForLoadedResult(
          sites: const <PollutionSite>[],
          locationAvailable: false,
          isStaleFallback: false,
        ),
        FeedSitesViewStatus.noLocation,
      );
      expect(
        feedStatusForLoadedResult(
          sites: const <PollutionSite>[],
          locationAvailable: true,
          isStaleFallback: false,
        ),
        FeedSitesViewStatus.empty,
      );
    },
  );
}
