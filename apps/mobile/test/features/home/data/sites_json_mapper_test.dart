import 'package:chisto_mobile/features/home/data/sites_json_mapper.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
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

  test('siteDetailFromJson picks earliest report when API lists newest first', () {
    final PollutionSite site = mapper.siteDetailFromJson(
      <String, dynamic>{
        'id': 'site-1',
        'description': 'River pollution',
        'status': 'VERIFIED',
        'latitude': 41.99,
        'longitude': 21.43,
        'upvotesCount': 2,
        'commentsCount': 0,
        'sharesCount': 0,
        'isUpvotedByMe': false,
        'isSavedByMe': false,
        'coReporterNames': <String>[],
        'mergedDuplicateChildCountTotal': 0,
        'reports': <dynamic>[
          <String, dynamic>{
            'id': 'report-new',
            'createdAt': '2026-05-20T12:00:00.000Z',
            'reporterId': 'user-new',
            'title': 'Newest report',
            'description': 'Latest body',
            'mediaUrls': <String>['https://cdn.example/new.jpg'],
            'reporter': <String, dynamic>{
              'firstName': 'New',
              'lastName': 'Reporter',
              'avatarUrl': 'https://cdn.example/new-avatar.jpg',
            },
            'coReporters': <dynamic>[],
            'mergedDuplicateChildCount': 0,
          },
          <String, dynamic>{
            'id': 'report-old',
            'createdAt': '2026-01-10T08:00:00.000Z',
            'reporterId': 'user-old',
            'title': 'First report',
            'description': 'Original body',
            'mediaUrls': <String>['https://cdn.example/old.jpg'],
            'reporter': <String, dynamic>{
              'firstName': 'Alice',
              'lastName': 'First',
              'avatarUrl': 'https://cdn.example/alice.jpg',
            },
            'coReporters': <dynamic>[],
            'mergedDuplicateChildCount': 0,
          },
        ],
        'events': <dynamic>[],
      },
    );

    expect(site.firstReport, isNotNull);
    expect(site.firstReport!.id, 'report-old');
    expect(site.firstReport!.reporterName, 'Alice First');
    expect(
      site.firstReport!.reporterAvatarUrl,
      'https://cdn.example/alice.jpg',
    );
    expect(
      site.firstReport!.reportedAt,
      DateTime.parse('2026-01-10T08:00:00.000Z'),
    );
    expect(site.displayFirstReport, same(site.firstReport));
    expect(site.latestReporterName, 'New Reporter');
    expect(site.latestReporterAvatarUrl, 'https://cdn.example/new-avatar.jpg');
    expect(site.latestReporterUserId, 'user-new');
  });
}
