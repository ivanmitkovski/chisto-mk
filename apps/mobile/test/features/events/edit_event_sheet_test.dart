import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/features/events/presentation/screens/edit_event_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_events_repository.dart';

EcoEvent _baseEvent() {
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
    date: DateTime.utc(2026, 6, 15),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 3,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime.utc(2026, 1, 1),
    maxParticipants: 20,
    moderationApproved: true,
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

  setUp(() {
    repo = RecordingEventsRepository(seed: <EcoEvent>[_baseEvent()]);
    EventsRepositoryRegistry.setTestOverride(repo);
  });

  tearDown(() {
    EventsRepositoryRegistry.setTestOverride(null);
  });

  testWidgets('save is disabled when form is not dirty', (WidgetTester tester) async {
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

  testWidgets('shows title validation after save with short title', (WidgetTester tester) async {
    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(ElevatedButton),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('at least'), findsOneWidget);
  });

  testWidgets('shows schedule conflict preview when API reports overlap', (WidgetTester tester) async {
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

  testWidgets('system back when dirty shows discard dialog', (WidgetTester tester) async {
    await tester.pumpWidget(_app(EditEventSheet(event: _baseEvent())));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).first, 'New title');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();

    expect(find.text('Discard'), findsOneWidget);
  });
}
