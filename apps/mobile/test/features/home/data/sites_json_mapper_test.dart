import 'package:chisto_mobile/features/home/data/sites_json_mapper.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SitesJsonMapper mapper = SitesJsonMapper();

  test('sitesListResultFromJson reads meta and nextCursor', () {
    final SitesListResult r = mapper.sitesListResultFromJson(
      <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 's1',
            'description': 'River bend',
            'status': 'VERIFIED',
            'reportCount': 2,
            'latestReportTitle': '',
            'latestReportDescription': '',
            'upvotesCount': 5,
            'commentsCount': 1,
            'sharesCount': 0,
            'latestReportMediaUrls': <String>['https://cdn.example/a.jpg'],
            'distanceKm': 2.5,
          },
        ],
        'meta': <String, dynamic>{
          'total': 99,
          'page': 1,
          'limit': 24,
          'nextCursor': 'abc',
        },
      },
      page: 1,
      limit: 24,
    );

    expect(r.sites, hasLength(1));
    expect(r.sites.first.id, 's1');
    expect(r.sites.first.mediaUrls.first, 'https://cdn.example/a.jpg');
    expect(r.total, 99);
    expect(r.nextCursor, 'abc');
  });
}
