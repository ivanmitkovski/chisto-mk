import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_schedule_conflict_preview.dart';
import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:feature_events/src/presentation/screens/edit_event_sheet.dart';
import 'package:feature_events/src/presentation/widgets/edit_event/edit_event_submit_banner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_events_repository.dart';
import '../../shared/widget_test_bootstrap.dart';

EcoEvent _baseEvent() {
  // Keep the schedule in the future relative to "now" so the upcoming event
  // stays valid (the sheet disables Save and skips the conflict preview when
  // the start time is in the past).
  final DateTime futureDate = DateUtils.dateOnly(
    DateTime.now(),
  ).add(const Duration(days: 30));
  return EcoEvent(
    id: 'e1',
    title: 'River cleanup',
    description: 'Desc',
    category: EcoEventCategory.riverAndLake,
    siteId: 's1',
    siteName: 'Vardar bend',
    siteImageUrl: '',
    siteDistanceKm: 2,
    organizerId: 'org-1',
    organizerName: 'Org',
    date: futureDate,
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 3,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime.utc(2026, 1, 1),
    maxParticipants: 20,
    moderationApproved: true,
  );
}

/// Upcoming event whose start time has already passed (e.g. a draft awaiting
/// moderation). Editing non-schedule fields must still be allowed.
EcoEvent _pastScheduleEvent() {
  final DateTime pastDate = DateUtils.dateOnly(
    DateTime.now(),
  ).subtract(const Duration(days: 2));
  return EcoEvent(
    id: 'e1',
    title: 'River cleanup',
    description: 'Desc',
    category: EcoEventCategory.riverAndLake,
    siteId: 's1',
    siteName: 'Vardar bend',
    siteImageUrl: '',
    siteDistanceKm: 2,
    organizerId: 'org-1',
    organizerName: 'Org',
    date: pastDate,
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 3,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime.utc(2026, 1, 1),
    maxParticipants: 20,
    moderationApproved: false,
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  late RecordingEventsRepository repo;

  setUpAll(bootstrapWidgetTests);

  setUp(() {
    repo = RecordingEventsRepository(seed: <EcoEvent>[_baseEvent()]);
    setEventsRepositoryTestOverride(repo);
  });

  tearDown(() {
    setEventsRepositoryTestOverride(null);
  });

  testWidgets('save is disabled when form is not dirty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final ElevatedButton saveBtn = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(saveBtn.onPressed, isNull);
  });

  testWidgets('save is disabled when title is too short', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.pump();

    final ElevatedButton saveBtn = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(saveBtn.onPressed, isNull);
  });

  testWidgets('shows title validation after blur when title is too short', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.pump();
    await tester.tap(find.byType(TextField).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.textContaining('at least'), findsOneWidget);
  });

  testWidgets(
    'successful title save calls repository and shows success snack',
    (WidgetTester tester) async {
      await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byType(TextField).first,
        'Updated river cleanup',
      );
      await tester.pump();

      await tester.tap(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(ElevatedButton),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.updateEventDetailsCallCount, 1);
      expect(
        repo.lastUpdateEventDetailsPayload?.title,
        'Updated river cleanup',
      );
      expect(find.text('Event updated'), findsOneWidget);
    },
  );

  testWidgets(
    'save stays enabled for title edits when the existing schedule is already past',
    (WidgetTester tester) async {
      final EcoEvent pastEvent = _pastScheduleEvent();
      repo = RecordingEventsRepository(seed: <EcoEvent>[pastEvent]);
      setEventsRepositoryTestOverride(repo);

      await tester.pumpWidget(_app(EditEventSheet(event: pastEvent)));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byType(TextField).first,
        'Updated title for past event',
      );
      await tester.pump();

      final ElevatedButton saveBtn = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(
        saveBtn.onPressed,
        isNotNull,
        reason:
            'Save should be enabled when only the title changes, even if '
            'the existing schedule is in the past',
      );

      await tester.tap(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(ElevatedButton),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.updateEventDetailsCallCount, 1);
      expect(
        repo.lastUpdateEventDetailsPayload?.title,
        'Updated title for past event',
      );
      expect(
        repo.lastUpdateEventDetailsPayload?.scheduledAtUtc,
        isNull,
        reason: 'An unchanged schedule must not be sent in the PATCH payload',
      );
    },
  );

  testWidgets('API error shows snack and keeps sheet open', (
    WidgetTester tester,
  ) async {
    repo.updateEventDetailsError = AppError.network(message: 'offline');

    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(
      find.byType(TextField).first,
      'Updated river cleanup',
    );
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(ElevatedButton),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repo.updateEventDetailsCallCount, 1);
    expect(find.byType(EditEventSheet), findsOneWidget);
    expect(find.byType(EditEventSubmitBanner), findsOneWidget);
  });

  testWidgets('shows schedule conflict preview when API reports overlap', (
    WidgetTester tester,
  ) async {
    repo.scheduleConflictOverride = EventScheduleConflictPreview(
      hasConflict: true,
      conflictingEvent: ConflictingEventInfo(
        id: 'other',
        title: 'Other event',
        scheduledAt: DateTime.utc(2026, 6, 10, 9, 0),
      ),
    );
    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Other event'), findsOneWidget);
  });

  testWidgets('system back when dirty shows discard dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).first, 'New title');
    await tester.pump();

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pump();
    await tester.pump();

    expect(find.text('Discard'), findsOneWidget);
  });

  testWidgets('title field stays just above keyboard in modal wrapper', (
    WidgetTester tester,
  ) async {
    const double keyboardInset = 300;
    const Size surfaceSize = Size(800, 1600);

    await tester.binding.setSurfaceSize(surfaceSize);
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      wrapForWidgetTest(
        MediaQuery(
          data: const MediaQueryData(size: surfaceSize),
          child: Builder(
            builder: (BuildContext context) {
              final MediaQueryData viewMq = MediaQueryData.fromView(
                View.of(context),
              );
              Widget sheet = wrapScrollControlledBottomSheet(
                context: context,
                keyboardInsetMode: SheetKeyboardInsetMode.overlay,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    viewInsets: viewMq.viewInsets,
                    viewPadding: viewMq.viewPadding,
                  ),
                  child: EditEventSheet(event: _baseEvent()),
                ),
              );
              sheet = MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: sheet,
              );
              return Align(alignment: Alignment.bottomCenter, child: sheet);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    final Finder titleField = find.byType(TextField).first;
    expect(titleField, findsOneWidget);

    await tester.tap(titleField);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    final Finder saveCta = find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.text('Save changes'),
    );
    expect(saveCta, findsOneWidget);

    final double keyboardTop = surfaceSize.height - keyboardInset;
    final Rect saveRect = tester.getRect(saveCta);
    final Rect fieldRect = tester.getRect(titleField);

    // The edit sheet keeps a fixed-height panel (padFooterForKeyboard: false):
    // the footer stays pinned at the sheet bottom behind the keyboard while the
    // focused title field remains visible above it.
    expect(
      fieldRect.bottom,
      lessThan(keyboardTop),
      reason: 'Focused title field should stay visible above the keyboard',
    );
    expect(
      saveRect.bottom,
      greaterThan(keyboardTop),
      reason: 'Footer stays pinned at the sheet bottom behind the keyboard',
    );
  });
}
