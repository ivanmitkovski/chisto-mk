import 'package:feature_home/src/data/sites_json_mapper.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SitesJsonMapper mapper = SitesJsonMapper();

  test('feed list prefers heroMediaUrls over latestReportMediaUrls', () {
    final SitesListResult r = mapper.sitesListResultFromJson(
      <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 's1',
            'description': 'River bend',
            'status': 'VERIFIED',
            'reportCount': 2,
            'latestReportTitle': 'Latest',
            'latestReportDescription': '',
            'upvotesCount': 5,
            'commentsCount': 1,
            'sharesCount': 0,
            'latestReportMediaUrls': <String>['https://cdn.example/latest.jpg'],
            'heroMediaUrls': <String>['https://cdn.example/hero.jpg'],
            'distanceKm': 2.5,
          },
        ],
        'meta': <String, dynamic>{
          'total': 1,
          'page': 1,
          'limit': 24,
          'nextCursor': null,
        },
      },
      page: 1,
      limit: 24,
    );

    expect(r.sites.single.mediaUrls, <String>['https://cdn.example/hero.jpg']);
  });

  test('feed list falls back to latestReportMediaUrls when heroMediaUrls empty', () {
    final SitesListResult r = mapper.sitesListResultFromJson(
      <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 's1',
            'description': 'River bend',
            'status': 'VERIFIED',
            'reportCount': 2,
            'latestReportTitle': 'Latest',
            'latestReportDescription': '',
            'upvotesCount': 5,
            'commentsCount': 1,
            'sharesCount': 0,
            'latestReportMediaUrls': <String>['https://cdn.example/latest.jpg'],
            'heroMediaUrls': <String>[],
            'distanceKm': 2.5,
          },
        ],
        'meta': <String, dynamic>{
          'total': 1,
          'page': 1,
          'limit': 24,
          'nextCursor': null,
        },
      },
      page: 1,
      limit: 24,
    );

    expect(r.sites.single.mediaUrls, <String>['https://cdn.example/latest.jpg']);
  });
}
