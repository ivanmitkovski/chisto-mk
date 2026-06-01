import 'package:feature_reports/src/data/api_reports_json_wrappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createReportSubmitPayload', () {
    test('unwraps gateway envelope with reportId', () {
      final Map<String, dynamic> inner = <String, dynamic>{
        'reportId': 'r-1',
        'status': 'pending',
      };
      final Map<String, dynamic> wrapped = <String, dynamic>{'data': inner};

      expect(createReportSubmitPayload(wrapped), inner);
    });

    test('returns root json when data is missing reportId', () {
      final Map<String, dynamic> root = <String, dynamic>{
        'reportId': 'r-2',
        'status': 'pending',
      };
      final Map<String, dynamic> wrapped = <String, dynamic>{
        'data': <String, dynamic>{'status': 'pending'},
      };

      expect(createReportSubmitPayload(root), root);
      expect(createReportSubmitPayload(wrapped), wrapped);
    });
  });

  group('singleResourceReportPayload', () {
    test('unwraps when data has id', () {
      final Map<String, dynamic> inner = <String, dynamic>{'id': 'r-3'};
      expect(
        singleResourceReportPayload(<String, dynamic>{'data': inner}),
        inner,
      );
    });

    test('unwraps when data has mediaUrls or title', () {
      final Map<String, dynamic> byMedia = <String, dynamic>{
        'mediaUrls': <String>['https://cdn/a.jpg'],
      };
      final Map<String, dynamic> byTitle = <String, dynamic>{'title': 'River'};

      expect(
        singleResourceReportPayload(<String, dynamic>{'data': byMedia}),
        byMedia,
      );
      expect(
        singleResourceReportPayload(<String, dynamic>{'data': byTitle}),
        byTitle,
      );
    });

    test('returns root when data lacks entity keys', () {
      final Map<String, dynamic> root = <String, dynamic>{'id': 'r-4'};
      final Map<String, dynamic> wrapped = <String, dynamic>{
        'data': <String, dynamic>{'status': 'pending'},
      };

      expect(singleResourceReportPayload(root), root);
      expect(singleResourceReportPayload(wrapped), wrapped);
    });
  });

  group('normalizeReportMediaFetchUrl', () {
    test('table-driven: trims and protocol-normalizes', () {
      final List<({String raw, String expected})> cases =
          <({String raw, String expected})>[
            (raw: '', expected: ''),
            (raw: '  ', expected: ''),
            (raw: ' https://cdn/a.jpg ', expected: 'https://cdn/a.jpg'),
            (
              raw: '//cdn.example.com/a.jpg',
              expected: 'https://cdn.example.com/a.jpg',
            ),
          ];
      for (final ({String raw, String expected}) c in cases) {
        expect(normalizeReportMediaFetchUrl(c.raw), c.expected);
      }
    });
  });

  group('reportMediaUrlsFromJson', () {
    test('returns empty when mediaUrls missing', () {
      expect(reportMediaUrlsFromJson(<String, dynamic>{}), isEmpty);
    });

    test('reads media_urls snake_case alias', () {
      expect(
        reportMediaUrlsFromJson(<String, dynamic>{
          'media_urls': <String>['https://cdn/a.jpg'],
        }),
        <String>['https://cdn/a.jpg'],
      );
    });

    test('table-driven: string and map entries with normalization', () {
      final List<String> urls = reportMediaUrlsFromJson(<String, dynamic>{
        'mediaUrls': <dynamic>[
          ' https://cdn/a.jpg ',
          '//cdn.example.com/b.jpg',
          '',
          <String, dynamic>{'url': 'https://cdn/c.jpg'},
          <String, dynamic>{'href': '//cdn.example.com/d.jpg'},
          42,
          <String, dynamic>{'url': '   '},
        ],
      });

      expect(urls, <String>[
        'https://cdn/a.jpg',
        'https://cdn.example.com/b.jpg',
        'https://cdn/c.jpg',
        'https://cdn.example.com/d.jpg',
      ]);
    });

    test('wraps single scalar as one-element list', () {
      expect(
        reportMediaUrlsFromJson(<String, dynamic>{
          'mediaUrls': 'https://cdn/solo.jpg',
        }),
        <String>['https://cdn/solo.jpg'],
      );
    });
  });
}
