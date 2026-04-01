import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/screens/create_event_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    InMemoryEventsStore.instance.resetToSeed();
  });

  testWidgets('requires site selection before creating an event', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: CreateEventSheet()),
      ),
    );

    await tester.ensureVisible(find.text('Create eco action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create eco action'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose the site before creating the event.'),
      findsOneWidget,
    );
  });

  testWidgets('returns created event after confirmation', (
    WidgetTester tester,
  ) async {
    EcoEvent? createdEvent;

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
                  onPressed: () async {
                    createdEvent = await Navigator.of(context).push<EcoEvent>(
                      MaterialPageRoute<EcoEvent>(
                        builder: (_) => const CreateEventSheet(
                          preselectedSiteId: '1',
                          preselectedSiteName: 'Illegal landfill near the river',
                          preselectedSiteImageUrl:
                              'assets/images/references/onboarding_reference.png',
                          preselectedSiteDistanceKm: 15,
                        ),
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

    await tester.enterText(
      find.byType(TextField).first,
      'Sunday river cleanup',
    );

    await tester.ensureVisible(find.text('Select event type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select event type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General cleanup').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create eco action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create eco action'));
    await tester.pumpAndSettle();

    expect(find.text('Event created'), findsOneWidget);

    await tester.tap(find.text('Open event'));
    await tester.pumpAndSettle();

    expect(createdEvent, isNotNull);
    expect(createdEvent!.title, equals('Sunday river cleanup'));
    expect(createdEvent!.siteId, equals('1'));
  });
}
