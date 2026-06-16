import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_notifications/src/domain/notifications_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('mk');
  });

  test('notificationDayTitle uses localized weekday for mk locale', () {
    final AppLocalizations mk = lookupAppLocalizations(const Locale('mk'));
    // 2026-06-10 is a Wednesday
    final DateTime wednesday = DateTime(2026, 6, 10);
    final String title = notificationDayTitle(
      mk,
      wednesday,
      now: DateTime(2026, 6, 16),
    );
    expect(title.toLowerCase(), contains('сре'));
  });

  test('notificationRelativeTime formats older dates with locale', () {
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    final String label = notificationRelativeTime(
      en,
      DateTime(2026, 1, 5),
    );
    expect(label, '05.01');
  });
}
