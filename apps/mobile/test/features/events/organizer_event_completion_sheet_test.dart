import 'dart:async';

import 'package:chisto_mobile/features/events/presentation/widgets/organizer_checkin/organizer_event_completion_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('completion sheet shows back and add photos actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    unawaited(
                      showOrganizerEventCompletionSheet(
                        context: context,
                        checkedInCount: 3,
                        participantCount: 8,
                        maxParticipants: 30,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Event ended'), findsOneWidget);
    expect(find.text('Back to event'), findsOneWidget);
    expect(find.text('View impact receipt'), findsOneWidget);
    expect(find.text('Add cleanup photos now'), findsOneWidget);
    expect(find.text('Thanks for organizing!'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Add after photos'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    expect(find.text('Add after photos'), findsOneWidget);
  });
}
