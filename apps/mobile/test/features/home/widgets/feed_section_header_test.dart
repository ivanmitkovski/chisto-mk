import 'package:chisto_mobile/features/home/presentation/widgets/feed_section_header.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FeedSectionHeader shows section title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: const Scaffold(
          body: FeedSectionHeader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pollution sites'), findsOneWidget);
  });
}
