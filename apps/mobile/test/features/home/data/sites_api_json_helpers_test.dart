import 'package:feature_home/src/data/sites_api_json_helpers.dart';
import 'package:feature_home/src/domain/models/co_reporter_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sitesApiJsonTruthy', () {
    test('table of truthy values', () {
      const List<(Object?, bool)> cases = <(Object?, bool)>[
        (true, true),
        (false, false),
        (null, false),
        (1, true),
        (0, false),
        ('true', true),
        ('TRUE', true),
        ('1', true),
        ('yes', true),
        ('no', false),
        ('', false),
        ('maybe', false),
      ];
      for (final (Object? input, bool expected) in cases) {
        expect(sitesApiJsonTruthy(input), expected, reason: '$input');
      }
    });
  });

  group('sitesApiJsonBoolField', () {
    test('reads camel or snake case', () {
      expect(
        sitesApiJsonBoolField(
          <String, dynamic>{'isSavedByMe': true},
          'isSavedByMe',
          'is_saved_by_me',
        ),
        isTrue,
      );
      expect(
        sitesApiJsonBoolField(
          <String, dynamic>{'is_saved_by_me': '1'},
          'isSavedByMe',
          'is_saved_by_me',
        ),
        isTrue,
      );
    });
  });

  group('sitesApiPublicReporterDisplayName', () {
    test('prefers first and last name', () {
      expect(
        sitesApiPublicReporterDisplayName(<String, dynamic>{
          'firstName': 'Ana',
          'lastName': 'K',
        }),
        'Ana K',
      );
    });

    test('uses snake_case names', () {
      expect(
        sitesApiPublicReporterDisplayName(<String, dynamic>{
          'first_name': 'Marko',
          'last_name': 'P',
        }),
        'Marko P',
      );
    });

    test('returns Anonymous when redacted', () {
      expect(
        sitesApiPublicReporterDisplayName(null),
        kSitesApiAnonymousCoReporterName,
      );
      expect(
        sitesApiPublicReporterDisplayName(<String, dynamic>{}),
        kSitesApiAnonymousCoReporterName,
      );
    });

    test('keeps abbreviated displayLabel when full name missing', () {
      expect(
        sitesApiPublicReporterDisplayName(<String, dynamic>{
          'displayLabel': 'K.',
        }),
        'K.',
      );
    });
  });

  group('sitesApiIsAbbreviatedReporterLabel', () {
    test('matches single initial labels', () {
      expect(sitesApiIsAbbreviatedReporterLabel('K.'), isTrue);
      expect(sitesApiIsAbbreviatedReporterLabel('Ana K'), isFalse);
    });
  });

  group('sitesApiSiteEntityJsonRoot', () {
    test('returns json when reports list is top-level', () {
      final Map<String, dynamic> root = <String, dynamic>{
        'id': 's1',
        'reports': <dynamic>[],
      };
      expect(sitesApiSiteEntityJsonRoot(root), same(root));
    });

    test('unwraps data.site with reports', () {
      final Map<String, dynamic> site = <String, dynamic>{
        'id': 's1',
        'reports': <dynamic>[],
      };
      final Map<String, dynamic> wrapped = <String, dynamic>{
        'data': <String, dynamic>{'site': site},
      };
      expect(sitesApiSiteEntityJsonRoot(wrapped), same(site));
    });

    test('unwraps flat data entity with coordinates', () {
      final Map<String, dynamic> entity = <String, dynamic>{
        'id': 's1',
        'latitude': 41.99,
        'longitude': 21.43,
      };
      final Map<String, dynamic> wrapped = <String, dynamic>{'data': entity};
      expect(sitesApiSiteEntityJsonRoot(wrapped), same(entity));
    });
  });

  group('sitesApiEarliestReport / sitesApiLatestReport', () {
    late List<Map<String, dynamic>> reports;

    setUp(() {
      reports = <Map<String, dynamic>>[
        <String, dynamic>{'id': 'new', 'createdAt': '2026-05-20T12:00:00.000Z'},
        <String, dynamic>{'id': 'old', 'createdAt': '2026-01-10T08:00:00.000Z'},
      ];
    });

    test('earliest picks minimum createdAt', () {
      expect(sitesApiEarliestReport(reports)['id'], 'old');
    });

    test('latest picks maximum createdAt', () {
      expect(sitesApiLatestReport(reports)['id'], 'new');
    });
  });

  group('sitesApiCoReporter helpers', () {
    test('row display name prefers nested user', () {
      expect(
        sitesApiCoReporterRowDisplayName(<String, dynamic>{
          'user': <String, dynamic>{'firstName': 'Ana', 'lastName': 'K'},
        }),
        'Ana K',
      );
    });

    test('preferRicherCoReporterName keeps named over Anonymous', () {
      expect(
        sitesApiPreferRicherCoReporterName(
          kSitesApiAnonymousCoReporterName,
          'Ana K',
        ),
        'Ana K',
      );
      expect(
        sitesApiPreferRicherCoReporterName(
          'Ana K',
          kSitesApiAnonymousCoReporterName,
        ),
        'Ana K',
      );
    });

    test('coReporterSummariesFromApiField maps profiles', () {
      final List<CoReporterProfile> profiles =
          sitesApiCoReporterSummariesFromApiField(<dynamic>[
            <String, dynamic>{
              'name': 'Ana K',
              'avatarUrl': 'https://cdn.example/a.webp',
              'userId': 'u1',
            },
          ]);

      expect(profiles.single.displayName, 'Ana K');
      expect(profiles.single.avatarUrl, 'https://cdn.example/a.webp');
      expect(profiles.single.userId, 'u1');
    });
  });

  group('sitesApiStringListFromJsonField', () {
    test('trims and skips empty strings', () {
      expect(
        sitesApiStringListFromJsonField(<dynamic>[' a ', '', 'b']),
        <String>['a', 'b'],
      );
      expect(sitesApiStringListFromJsonField('not-list'), isEmpty);
    });
  });

  group('sitesApiPreferNonEmptyString', () {
    test('returns first non-empty trimmed value', () {
      expect(sitesApiPreferNonEmptyString('  hi ', null), 'hi');
      expect(sitesApiPreferNonEmptyString(null, ' there '), 'there');
      expect(sitesApiPreferNonEmptyString(' ', ''), isNull);
    });
  });
}
