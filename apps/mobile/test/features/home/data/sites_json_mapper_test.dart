import 'package:feature_home/src/data/sites_json_mapper.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
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

  test(
    'siteDetailFromJson picks earliest report when API lists newest first',
    () {
      final PollutionSite site = mapper.siteDetailFromJson(<String, dynamic>{
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
      });

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
      expect(
        site.latestReporterAvatarUrl,
        'https://cdn.example/new-avatar.jpg',
      );
      expect(site.latestReporterUserId, 'user-new');
      expect(site.mediaUrls, <String>['https://cdn.example/old.jpg']);
      expect(site.title, 'River pollution');
    },
  );

  test(
    'siteDetailFromJson prefers firstName/lastName over abbreviated displayLabel',
    () {
      final PollutionSite site = mapper.siteDetailFromJson(<String, dynamic>{
        'id': 'site-abbrev',
        'status': 'REPORTED',
        'reports': <dynamic>[
          <String, dynamic>{
            'id': 'report-1',
            'createdAt': '2026-05-01T10:00:00.000Z',
            'title': 'Cubrina',
            'mediaUrls': <String>[],
            'reporter': <String, dynamic>{
              'displayLabel': 'K.',
              'firstName': 'Kristina',
              'lastName': 'Petrova',
            },
            'coReporters': <dynamic>[],
          },
        ],
        'events': <dynamic>[],
      });

      expect(site.firstReport!.reporterName, 'Kristina Petrova');
    },
  );

  test(
    'siteDetailFromJson uses displayLabel full name when firstName/lastName omitted',
    () {
      final PollutionSite site = mapper.siteDetailFromJson(<String, dynamic>{
        'id': 'site-2',
        'status': 'REPORTED',
        'reports': <dynamic>[
          <String, dynamic>{
            'id': 'report-1',
            'createdAt': '2026-05-01T10:00:00.000Z',
            'title': 'Illegal dump',
            'mediaUrls': <String>['https://cdn.example/one.jpg'],
            'reporter': <String, dynamic>{
              'displayLabel': 'Ivan Petrov',
              'avatarUrl': null,
            },
            'coReporters': <dynamic>[],
          },
        ],
        'events': <dynamic>[],
      });

      expect(site.firstReport!.reporterName, 'Ivan Petrov');
      expect(site.latestReporterName, 'Ivan Petrov');
    },
  );

  test('siteDetailFromJson title and hero media use earliest report only', () {
    final PollutionSite site = mapper.siteDetailFromJson(<String, dynamic>{
      'id': 'site-3',
      'description': '',
      'status': 'REPORTED',
      'reports': <dynamic>[
        <String, dynamic>{
          'id': 'report-new',
          'createdAt': '2026-05-20T12:00:00.000Z',
          'title': 'Newest title',
          'mediaUrls': <String>['https://cdn.example/new.jpg'],
          'reporter': <String, dynamic>{'displayLabel': 'N.'},
          'coReporters': <dynamic>[],
        },
        <String, dynamic>{
          'id': 'report-old',
          'createdAt': '2026-01-10T08:00:00.000Z',
          'title': 'Earliest title',
          'mediaUrls': <String>['https://cdn.example/old.jpg'],
          'reporter': <String, dynamic>{'displayLabel': 'A.'},
          'coReporters': <dynamic>[],
        },
      ],
      'events': <dynamic>[],
    });

    expect(site.title, 'Earliest title');
    expect(site.mediaUrls, <String>['https://cdn.example/old.jpg']);
  });

  test('siteDetailFromJson prefers API heroMediaUrls when provided', () {
    final PollutionSite site = mapper.siteDetailFromJson(<String, dynamic>{
      'id': 'site-4',
      'heroMediaUrls': <String>['https://cdn.example/hero.jpg'],
      'heroReporter': <String, dynamic>{'displayLabel': 'H.'},
      'reports': <dynamic>[
        <String, dynamic>{
          'id': 'report-old',
          'createdAt': '2026-01-10T08:00:00.000Z',
          'title': 'Earliest',
          'mediaUrls': <String>['https://cdn.example/old.jpg'],
          'reporter': <String, dynamic>{'displayLabel': 'A.'},
          'coReporters': <dynamic>[],
        },
      ],
      'events': <dynamic>[],
    });

    expect(site.mediaUrls, <String>['https://cdn.example/hero.jpg']);
    expect(site.firstReport!.reporterName, 'H.');
  });

  test(
    'siteDetailFromJson co-reporter row uses displayLabel on nested user',
    () {
      final PollutionSite site = mapper.siteDetailFromJson(<String, dynamic>{
        'id': 'site-5',
        'reports': <dynamic>[
          <String, dynamic>{
            'id': 'report-1',
            'createdAt': '2026-05-01T10:00:00.000Z',
            'title': 'Dump',
            'mediaUrls': <String>[],
            'reporter': <String, dynamic>{'displayLabel': 'P.'},
            'coReporters': <dynamic>[
              <String, dynamic>{
                'userId': 'user-co',
                'reportedAt': '2026-05-02T10:00:00.000Z',
                'user': <String, dynamic>{'displayLabel': 'B.'},
              },
            ],
          },
        ],
        'events': <dynamic>[],
      });

      expect(site.coReporterProfiles, hasLength(1));
      expect(site.coReporterProfiles.first.displayName, 'B.');
    },
  );
}
