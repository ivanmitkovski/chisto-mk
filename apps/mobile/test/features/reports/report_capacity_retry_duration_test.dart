import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_retry_duration.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  group('formatReportCapacityRetryDuration', () {
    test('uses soon for null or non-positive', () {
      expect(
        formatReportCapacityRetryDuration(l10n, null),
        l10n.reportCooldownRetrySoon,
      );
      expect(
        formatReportCapacityRetryDuration(l10n, 0),
        l10n.reportCooldownRetrySoon,
      );
    });

    test('formats days, hours, and minutes', () {
      const int sixDays23h57m = 6 * 86400 + 23 * 3600 + 57 * 60;
      final String s = formatReportCapacityRetryDuration(l10n, sixDays23h57m);
      expect(s, contains('6 days'));
      expect(s, contains('23 hours'));
      expect(s, contains('57 minutes'));
    });

    test('formats hours and minutes without days', () {
      expect(
        formatReportCapacityRetryDuration(l10n, 7260),
        '2 hours, 1 minute',
      );
    });

    test('formats seconds when under one minute', () {
      expect(formatReportCapacityRetryDuration(l10n, 45), '45 seconds');
    });
  });
}
