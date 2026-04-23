import 'package:chisto_mobile/features/events/presentation/widgets/event_success_dialog.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requiresModeration shows pending copy and View event CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: EventSuccessDialog(
            title: 'River cleanup',
            siteName: 'Test site',
            requiresModeration: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Submitted for review'), findsOneWidget);
    expect(
      find.textContaining('moderator'),
      findsOneWidget,
    );
    expect(find.text('View event'), findsOneWidget);
    expect(find.text('Event created'), findsNothing);
  });

  testWidgets('approved path shows live copy', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: EventSuccessDialog(
            title: 'River cleanup',
            siteName: 'Test site',
            requiresModeration: false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Event created'), findsOneWidget);
    expect(find.textContaining('Share'), findsOneWidget);
    expect(find.text('View event'), findsOneWidget);
  });
}
