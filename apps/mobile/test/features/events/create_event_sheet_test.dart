// Manual QA (create event): small phone (e.g. iPhone SE), large accessibility text,
// dark mode; focus a text field — primary CTA stays fixed at bottom (may sit under keyboard; scroll form);
// open the site picker and confirm loading, offline banner when applicable, and retry on error;
// edit the form and use the system/back affordance to confirm the discard dialog;
// exercise volunteer cap presets and custom values (2–5000);
// open via named route (CupertinoPageRoute) and confirm iOS edge swipe-back matches discard rules;
// brief bootstrap skeleton then form fade-in; reduced motion skips section stagger.

import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/screens/create_event_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_sticky_footer.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_calendar.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settlePastCreateEventBootstrap(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 420));
  await tester.pumpAndSettle();
}

void main() {
  test('AppRoutes.eventsCreate uses CupertinoPageRoute for interactive pop', () {
    final Route<dynamic> route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.eventsCreate),
    );
    expect(route, isA<CupertinoPageRoute<Object?>>());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    InMemoryEventsStore.instance.resetToSeed();
    EventsRepositoryRegistry.setTestOverride(InMemoryEventsStore.instance);
  });

  tearDown(() {
    EventsRepositoryRegistry.setTestOverride(null);
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

    await settlePastCreateEventBootstrap(tester);
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
    await settlePastCreateEventBootstrap(tester);

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

  testWidgets('progress reflects validation milestones (not title length alone)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: CreateEventSheet(
            preselectedSiteId: '1',
            preselectedSiteName: 'Illegal landfill near the river',
            preselectedSiteImageUrl:
                'assets/images/references/onboarding_reference.png',
            preselectedSiteDistanceKm: 15,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settlePastCreateEventBootstrap(tester);

    expect(find.text('Step 3 of 5'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.pump();
    expect(find.text('Step 3 of 5'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();
    expect(find.text('Step 4 of 5'), findsOneWidget);
  });

  testWidgets('short title shows min-length error on submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: CreateEventSheet(
            preselectedSiteId: '1',
            preselectedSiteName: 'Illegal landfill near the river',
            preselectedSiteImageUrl:
                'assets/images/references/onboarding_reference.png',
            preselectedSiteDistanceKm: 15,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settlePastCreateEventBootstrap(tester);

    await tester.enterText(find.byType(TextField).first, 'ab');
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

    expect(
      find.text('Use at least 3 characters for the title.'),
      findsOneWidget,
    );
  });

  testWidgets('schedule calendar opens focused on current month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: CreateEventSheet(
            preselectedSiteId: '1',
            preselectedSiteName: 'Illegal landfill near the river',
            preselectedSiteImageUrl:
                'assets/images/references/onboarding_reference.png',
            preselectedSiteDistanceKm: 15,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settlePastCreateEventBootstrap(tester);

    final BuildContext calContext = tester.element(find.byType(EventCalendar));
    final MaterialLocalizations loc = MaterialLocalizations.of(calContext);
    final DateTime now = DateTime.now();
    final String monthLabel =
        loc.formatMonthYear(DateTime(now.year, now.month));
    expect(find.text(monthLabel), findsOneWidget);
  });

  testWidgets('primary CTA lives in sticky footer without scrolling the form', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: CreateEventSheet(
            preselectedSiteId: '1',
            preselectedSiteName: 'Illegal landfill near the river',
            preselectedSiteImageUrl:
                'assets/images/references/onboarding_reference.png',
            preselectedSiteDistanceKm: 15,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settlePastCreateEventBootstrap(tester);

    final Finder stickyCta = find.descendant(
      of: find.byType(CreateEventStickyFooter),
      matching: find.byType(PrimaryButton),
    );
    expect(stickyCta, findsOneWidget);
  });

  testWidgets('sticky primary CTA stays at bottom when keyboard inset is large', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: 280),
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: CreateEventSheet(
              preselectedSiteId: '1',
              preselectedSiteName: 'Illegal landfill near the river',
              preselectedSiteImageUrl:
                  'assets/images/references/onboarding_reference.png',
              preselectedSiteDistanceKm: 15,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settlePastCreateEventBootstrap(tester);

    final Finder stickyCta = find.descendant(
      of: find.byType(CreateEventStickyFooter),
      matching: find.byType(PrimaryButton),
    );
    expect(stickyCta, findsOneWidget);

    const double screenH = 1600;
    final Rect buttonRect = tester.getRect(stickyCta);
    expect(
      buttonRect.bottom,
      greaterThan(screenH * 0.88),
      reason: 'CTA should remain near the physical bottom, not lift with viewInsets',
    );
  });

  testWidgets('volunteer cap preset is sent on created event', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

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
    await settlePastCreateEventBootstrap(tester);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey<String>('create_event_volunteer_cap')),
      find.byType(CustomScrollView),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('create_event_volunteer_cap')));
    await tester.pumpAndSettle();
    final Finder preset15 = find.byWidgetPredicate(
      (Widget w) => w is ReportActionTile && (w as ReportActionTile).title == '15',
    );
    await tester.ensureVisible(preset15);
    await tester.pumpAndSettle();
    await tester.tap(preset15);
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

    await tester.tap(find.text('Create eco action'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open event'));
    await tester.pumpAndSettle();

    expect(createdEvent, isNotNull);
    expect(createdEvent!.maxParticipants, equals(15));
  });

  testWidgets('create event sheet tolerates large accessibility text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.45),
            ),
            child: child!,
          );
        },
        home: const Scaffold(
          body: CreateEventSheet(
            preselectedSiteId: '1',
            preselectedSiteName: 'Illegal landfill near the river',
            preselectedSiteImageUrl:
                'assets/images/references/onboarding_reference.png',
            preselectedSiteDistanceKm: 15,
          ),
        ),
      ),
    );

    await settlePastCreateEventBootstrap(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
