import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/site_quick_actions.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SiteQuickActions shows localized save and share labels',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: Scaffold(
          body: SiteQuickActions(
            isSaved: false,
            isReported: false,
            onSaveTap: () {},
            onReportTap: () {},
            onShareTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save site'), findsOneWidget);
    expect(find.text('Report issue'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('SiteQuickActions shows Saved when isSaved', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: Scaffold(
          body: SiteQuickActions(
            isSaved: true,
            isReported: false,
            onSaveTap: () {},
            onReportTap: () {},
            onShareTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Save site'), findsNothing);
  });

  testWidgets('SiteQuickActions shows Reported when isReported', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: Scaffold(
          body: SiteQuickActions(
            isSaved: false,
            isReported: true,
            onSaveTap: () {},
            onReportTap: () {},
            onShareTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reported'), findsOneWidget);
    expect(find.text('Report issue'), findsNothing);
  });
}
