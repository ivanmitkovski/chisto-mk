// Manual QA (create event): small phone (e.g. iPhone SE), large accessibility text;
// focus the description field — it scrolls into view above the keyboard and sticky CTA;
// open the site picker and confirm loading, offline banner when applicable, and retry on error;
// edit the form and use the system/back affordance to confirm the discard dialog;
// exercise volunteer cap presets and custom values (2–5000);
// open via named route (CupertinoPageRoute) and confirm iOS edge swipe-back matches discard rules;
// brief bootstrap skeleton then form fade-in; reduced motion skips section stagger.

import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/screens/create_event_sheet.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_sticky_footer.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/pump_until_idle.dart';
import '../../shared/widget_test_bootstrap.dart';
import '../../support/events/in_memory_events_store.dart';

/// Fixed wall time so schedule validation and step progress are CI-stable.
DateTime createEventSheetTestClock() => DateTime(2026, 6, 15, 10, 0);

Future<void> settlePastCreateEventBootstrap(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 420));
  await pumpUntilIdle(tester);
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test(
    'AppRoutes.eventsCreate uses CupertinoPageRoute for interactive pop',
    () {
      final Route<dynamic> route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.eventsCreate),
      );
      expect(route, isA<CupertinoPageRoute<Object?>>());
    },
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    InMemoryEventsStore.instance.resetToSeed();
    setEventsRepositoryTestOverride(InMemoryEventsStore.instance);
    if (AppBootstrap.instance.isInitialized) {
      AppBootstrap.instance.authState.setAuthenticated(
        userId: 'u-test',
        displayName: 'Tester',
        organizerCertifiedAt: DateTime(2026, 1, 1),
        syncOrganizerCertifiedAt: true,
      );
    }
  });

  tearDown(() {
    setEventsRepositoryTestOverride(null);
  });

  testWidgets(
    'uncertified user is redirected from CreateEventSheet to toolkit',
    (WidgetTester tester) async {
      AppBootstrap.instance.authState.setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        organizerCertifiedAt: null,
        syncOrganizerCertifiedAt: true,
      );

      await tester.pumpWidget(
        wrapForWidgetTest(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: CreateEventSheet(clock: createEventSheetTestClock),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(OrganizerToolkitScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    },
  );

  testWidgets('requires site selection before creating an event', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        const Scaffold(
          body: CreateEventSheet(clock: createEventSheetTestClock),
        ),
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
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    createdEvent = await Navigator.of(context).push<EcoEvent>(
                      MaterialPageRoute<EcoEvent>(
                        builder: (_) => const CreateEventSheet(
                          clock: createEventSheetTestClock,
                          preselectedSiteId: '1',
                          preselectedSiteName:
                              'Illegal landfill near the river',
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

    expect(find.text('Submitted for review'), findsOneWidget);

    await tester.tap(find.text('View event'));
    await tester.pumpAndSettle();

    expect(createdEvent, isNotNull);
    expect(createdEvent!.title, equals('Sunday river cleanup'));
    expect(createdEvent!.siteId, equals('1'));
  });

  testWidgets(
    'progress reflects validation milestones (not title length alone)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForWidgetTest(
          const Scaffold(
            body: CreateEventSheet(
              clock: createEventSheetTestClock,
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
    },
  );

  testWidgets('short title shows min-length error on submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        const Scaffold(
          body: CreateEventSheet(
            clock: createEventSheetTestClock,
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
      wrapForWidgetTest(
        const Scaffold(
          body: CreateEventSheet(
            clock: createEventSheetTestClock,
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

    final BuildContext calContext = tester.element(
      find.byType(EventCalendar).first,
    );
    final MaterialLocalizations loc = MaterialLocalizations.of(calContext);
    final DateTime anchor = createEventSheetTestClock();
    final String monthLabel = loc.formatMonthYear(
      DateTime(anchor.year, anchor.month),
    );
    expect(find.text(monthLabel), findsWidgets);
  });

  testWidgets('primary CTA lives in sticky footer without scrolling the form', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      wrapForWidgetTest(
        const Scaffold(
          body: CreateEventSheet(
            clock: createEventSheetTestClock,
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

  testWidgets('sticky primary CTA stays at viewport bottom when keyboard opens', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    const double keyboardInset = 280;
    const Size surfaceSize = Size(800, 1600);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: surfaceSize,
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: wrapForWidgetTest(
          const Scaffold(
            body: CreateEventSheet(
              clock: createEventSheetTestClock,
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

    final Rect buttonRect = tester.getRect(stickyCta);
    expect(
      buttonRect.bottom,
      closeTo(surfaceSize.height - keyboardInset, 48),
      reason:
          'Footer should stay at the bottom of the inset viewport without lifting',
    );
  });

  testWidgets('form body stays flush with sticky footer when keyboard opens', (
    WidgetTester tester,
  ) async {
    const Size surfaceSize = Size(800, 1600);
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    const Widget sheet = Scaffold(
      body: CreateEventSheet(
        clock: createEventSheetTestClock,
        preselectedSiteId: '1',
        preselectedSiteName: 'Illegal landfill near the river',
        preselectedSiteImageUrl:
            'assets/images/references/onboarding_reference.png',
        preselectedSiteDistanceKm: 15,
      ),
    );

    await tester.pumpWidget(
      wrapForWidgetTest(
        const MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            viewInsets: EdgeInsets.only(bottom: 280),
          ),
          child: sheet,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settlePastCreateEventBootstrap(tester);

    final Finder expanded = find.ancestor(
      of: find.byType(CustomScrollView),
      matching: find.byType(Expanded),
    );
    final Rect expandedRect = tester.getRect(expanded);
    final Rect footerRect = tester.getRect(
      find.byType(CreateEventStickyFooter),
    );

    expect(
      expandedRect.bottom,
      closeTo(footerRect.top, 2),
      reason:
          'Form body should sit directly above the sticky footer (no gray gap)',
    );
    expect(
      footerRect.bottom,
      closeTo(surfaceSize.height - 280, 48),
      reason: 'Footer should stay at viewport bottom when keyboard opens',
    );
  });

  testWidgets('title field scrolls above keyboard when focused', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    const double keyboardInset = 280;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 280)),
        child: wrapForWidgetTest(
          const Scaffold(
            body: CreateEventSheet(
              clock: createEventSheetTestClock,
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

    final Finder titleHint = find.text('e.g. Weekend river cleanup');
    await tester.tap(titleHint);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    final Rect fieldRect = tester.getRect(titleHint);
    const double screenH = 1600;
    expect(
      fieldRect.bottom,
      lessThan(screenH - keyboardInset - 40),
      reason: 'Title should sit above the keyboard inset zone',
    );
  });

  testWidgets('description field scrolls above keyboard when focused', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    const double keyboardInset = 280;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 280)),
        child: wrapForWidgetTest(
          const Scaffold(
            body: CreateEventSheet(
              clock: createEventSheetTestClock,
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

    final Finder descriptionHint = find.text(
      'Describe what to expect, meeting point, etc.',
    );
    await tester.dragUntilVisible(
      descriptionHint,
      find.byType(CustomScrollView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();

    await tester.tap(descriptionHint);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    final Rect fieldRect = tester.getRect(descriptionHint);
    const double screenH = 1600;
    expect(
      fieldRect.bottom,
      lessThan(screenH - keyboardInset - 40),
      reason: 'Description should sit above the keyboard inset zone',
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
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    createdEvent = await Navigator.of(context).push<EcoEvent>(
                      MaterialPageRoute<EcoEvent>(
                        builder: (_) => const CreateEventSheet(
                          clock: createEventSheetTestClock,
                          preselectedSiteId: '1',
                          preselectedSiteName:
                              'Illegal landfill near the river',
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
    await tester.tap(
      find.byKey(const ValueKey<String>('create_event_volunteer_cap')),
    );
    await tester.pumpAndSettle();
    final Finder preset15 = find.byWidgetPredicate(
      (Widget w) => w is ReportActionTile && w.title == '15',
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

    await tester.tap(find.text('View event'));
    await tester.pumpAndSettle();

    expect(createdEvent, isNotNull);
    expect(createdEvent!.maxParticipants, equals(15));
  });

  testWidgets('create event sheet tolerates large accessibility text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.45)),
          child: Scaffold(
            body: CreateEventSheet(
              clock: createEventSheetTestClock,
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

    await settlePastCreateEventBootstrap(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
