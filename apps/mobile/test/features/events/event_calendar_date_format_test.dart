import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('formatEventCalendarDate uses app locale', (WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        supportedLocales: const <Locale>[Locale('en', 'US')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (BuildContext c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final String formatted = formatEventCalendarDate(ctx, DateTime(2025, 6, 15));
    expect(
      formatted,
      DateFormat('MMM d, y', 'en_US').format(DateTime(2025, 6, 15)),
    );
  });
}
