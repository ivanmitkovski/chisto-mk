import 'package:chisto_mobile/features/reports/domain/report_field_limits.dart';
import 'package:chisto_mobile/features/reports/domain/report_input_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportInputSanitizer', () {
    test('title strips disallowed controls and maps tab to space', () {
      expect(ReportInputSanitizer.sanitizeTitle('A\u0000B\tC'), 'AB C');
    });

    test('title clamp truncates after sanitize', () {
      final String long = 'y' * (ReportFieldLimits.maxTitleLength + 12);
      final String got = ReportInputSanitizer.clampTitle(long);
      expect(got.length, ReportFieldLimits.maxTitleLength);
      expect(got, 'y' * ReportFieldLimits.maxTitleLength);
    });

    test('description keeps newlines and strips other controls', () {
      expect(
        ReportInputSanitizer.sanitizeDescription('a\u0000b\nc'),
        'ab\nc',
      );
    });

    test('description preserves RTL mark and ZWSP (non-control)', () {
      const String rtl = '\u202e';
      const String zwsp = '\u200b';
      expect(
        ReportInputSanitizer.sanitizeDescription('x$rtl${zwsp}y'),
        'x$rtl${zwsp}y',
      );
    });

    test('description clamp applies after sanitize', () {
      final String long = '${'z' * (ReportFieldLimits.maxDescriptionLength + 4)}\nend';
      final String got = ReportInputSanitizer.clampDescription(long);
      expect(got.length, ReportFieldLimits.maxDescriptionLength);
    });

    test('table-driven: trim and empty edge cases', () {
      final List<({String title, String expected})> titleCases =
          <({String title, String expected})>[
            (title: '   ', expected: ''),
            (title: ' ok ', expected: 'ok'),
          ];
      for (final ({String title, String expected}) c in titleCases) {
        expect(ReportInputSanitizer.clampTitle(c.title), c.expected);
      }
    });
  });
}
