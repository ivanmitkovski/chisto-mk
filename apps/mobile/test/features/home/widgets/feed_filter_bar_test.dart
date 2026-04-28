import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_bar.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FeedFilterBar builds chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: Scaffold(
          body: FeedFilterBar(
            activeFilter: FeedFilter.all,
            onFilterSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FilterChip), findsWidgets);
  });
}
