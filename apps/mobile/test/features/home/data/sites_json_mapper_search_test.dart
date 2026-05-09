import 'package:chisto_mobile/features/home/data/sites_json_mapper.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SitesJsonMapper map search', () {
    const SitesJsonMapper mapper = SitesJsonMapper();

    test('siteMapSearchResponseFromJson maps items, suggestions, geoIntent', () {
      final result = mapper.siteMapSearchResponseFromJson(<String, dynamic>{
        'items': <dynamic>[
          <String, dynamic>{
            'id': 's1',
            'latitude': 41.99,
            'longitude': 21.43,
            'description': 'Waste',
            'address': ' Skopje Center ',
            'status': 'REPORTED',
          },
        ],
        'suggestions': <dynamic>['Skopje Center'],
        'geoIntent': <String, dynamic>{
          'label': 'Skopje',
          'minLat': 41.93,
          'maxLat': 42.07,
          'minLng': 21.33,
          'maxLng': 21.57,
        },
      });
      expect(result.items, hasLength(1));
      expect(result.items.single.id, 's1');
      expect(result.items.single.title, 'Skopje Center');
      expect(result.suggestions, <String>['Skopje Center']);
      expect(result.geoIntent?.label, 'Skopje');
      expect(result.geoIntent?.minLat, 41.93);
    });

    test('siteListItemToJson round-trips through siteListItemFromJson', () {
      final original = mapper.siteListItemFromJson(<String, dynamic>{
        'id': 'r1',
        'description': 'River bank',
        'latestReportTitle': '',
        'latestReportDescription': '',
        'status': 'VERIFIED',
        'pollutionType': 'PLASTIC',
        'latitude': 41.2,
        'longitude': 21.1,
        'upvotesCount': 3,
        'commentsCount': 1,
        'sharesCount': 0,
        'latestReportMediaUrls': <String>[],
      });
      final Map<String, dynamic> json = mapper.siteListItemToJson(original);
      final PollutionSite restored = mapper.siteListItemFromJson(json);
      expect(restored.id, original.id);
      expect(restored.description, original.description);
      expect(restored.statusCode, original.statusCode);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });
  });
}
