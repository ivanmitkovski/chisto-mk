import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/map_preview_hydration.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_pollution_site.dart';

PollutionSite _reportedSite({
  String title = 'My report',
  List<String> mediaUrls = const <String>['https://example.com/a.jpg'],
}) {
  return buildTestPollutionSite(id: 'site-1').copyWith(
    title: title,
    mediaUrls: mediaUrls,
  );
}

void main() {
  test('mapPreviewNeedsHydration is true for REPORTED sites without media', () {
    expect(
      mapPreviewNeedsHydration(_reportedSite(mediaUrls: const <String>[])),
      isTrue,
    );
  });

  test('mapPreviewNeedsHydration is true for generic title', () {
    expect(
      mapPreviewNeedsHydration(_reportedSite(title: 'Pollution site')),
      isTrue,
    );
  });

  test('mapPreviewNeedsHydration is false for enriched pending preview', () {
    expect(mapPreviewNeedsHydration(_reportedSite()), isFalse);
  });

  test('mapPreviewNeedsHydration is false for verified sites', () {
    expect(
      mapPreviewNeedsHydration(
        _reportedSite().copyWith(statusCode: 'VERIFIED'),
      ),
      isFalse,
    );
  });
}
