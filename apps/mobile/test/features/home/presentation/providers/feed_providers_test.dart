import 'package:chisto_mobile/features/home/presentation/providers/feed_providers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feedServerFetchGroup treats saved as distinct from hybrid feed', () {
    expect(feedServerFetchGroup(FeedFilter.all), feedServerFetchGroup(FeedFilter.mostVoted));
    expect(feedServerFetchGroup(FeedFilter.saved), isNot(feedServerFetchGroup(FeedFilter.all)));
    expect(feedServerFetchGroup(FeedFilter.saved), isNot(feedServerFetchGroup(FeedFilter.recent)));
  });
}
