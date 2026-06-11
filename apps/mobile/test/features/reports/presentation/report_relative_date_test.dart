import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/presentation/l10n/report_relative_date.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('en');
  });

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  String label(DateTime date, DateTime now) =>
      reportRelativeDateLabel(l10n, date, locale: 'en', now: now);

  group('reportRelativeDateLabel', () {
    test(
      'report submitted yesterday is "Yesterday" even when < 24h elapsed '
      '(regression for CH-000077 showing "Today")',
      () {
        // Jun 9 18:00 UTC viewed Jun 10 17:48 UTC: ~23h48m elapsed but a
        // different calendar day -> must be Yesterday, not Today.
        final String result = label(
          DateTime.utc(2026, 6, 9, 18, 0),
          DateTime.utc(2026, 6, 10, 17, 48),
        );
        expect(result, l10n.profilePointsHistoryDayYesterday);
        expect(result, isNot(l10n.eventsDateRelativeToday));
      },
    );

    test('same calendar day is "Today"', () {
      expect(
        label(DateTime.utc(2026, 6, 10, 1, 0), DateTime.utc(2026, 6, 10, 23, 0)),
        l10n.eventsDateRelativeToday,
      );
    });

    test('crossing midnight by 2h is "Yesterday" (calendar-day, not 24h)', () {
      expect(
        label(DateTime.utc(2026, 6, 9, 23, 0), DateTime.utc(2026, 6, 10, 1, 0)),
        l10n.profilePointsHistoryDayYesterday,
      );
    });

    test('three calendar days ago uses days-ago copy', () {
      expect(
        label(DateTime.utc(2026, 6, 7, 12, 0), DateTime.utc(2026, 6, 10, 12, 0)),
        l10n.eventsDateRelativeDaysAgo(3),
      );
    });

    test('nine days ago uses weeks-ago copy', () {
      expect(
        label(DateTime.utc(2026, 6, 1, 12, 0), DateTime.utc(2026, 6, 10, 12, 0)),
        l10n.reportListDateWeeksAgo(1),
      );
    });

    test('older than 30 days uses absolute date', () {
      final DateTime date = DateTime.utc(2026, 4, 1, 12, 0);
      expect(
        label(date, DateTime.utc(2026, 6, 10, 12, 0)),
        DateFormat.yMd('en').format(date),
      );
    });

    test('future timestamp (clock skew) is "Today", never negative buckets', () {
      expect(
        label(DateTime.utc(2026, 6, 11, 12, 0), DateTime.utc(2026, 6, 10, 12, 0)),
        l10n.eventsDateRelativeToday,
      );
    });

    test('local (non-UTC) timestamps compare by their own calendar day', () {
      final DateTime date = DateTime(2026, 6, 9, 18, 0);
      final DateTime now = DateTime(2026, 6, 10, 9, 0);
      expect(
        reportRelativeDateLabel(l10n, date, locale: 'en', now: now),
        l10n.profilePointsHistoryDayYesterday,
      );
    });
  });
}
