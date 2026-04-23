import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_schedule_constraints.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/extend_event_end_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_events_repository.dart';

void main() {
  tearDown(() {
    ConnectivityGate.check = () => Connectivity().checkConnectivity();
  });

  testWidgets('+15 preset issues updateEventDetails with bumped endAtUtc',
      (WidgetTester tester) async {
    ConnectivityGate.check = () async => <ConnectivityResult>[
      ConnectivityResult.wifi,
    ];
    // Tomorrow keeps schedule well above `now + minLead` so validation is not clock-sensitive.
    final DateTime now = DateTime.now();
    final DateTime d =
        DateUtils.dateOnly(now).add(const Duration(days: 1));
    const EventTime startT = EventTime(hour: 10, minute: 0);
    const EventTime endT = EventTime(hour: 18, minute: 0);
    expect(
      validateInProgressEditSchedule(
        dateOnly: d,
        start: startT,
        end: endT,
        now: now,
      ),
      isNull,
    );
    final EcoEvent event = EcoEvent(
      id: 'e1',
      title: 'T',
      description: 'D',
      category: EcoEventCategory.generalCleanup,
      siteId: 's',
      siteName: 'Site',
      siteImageUrl: '',
      siteDistanceKm: 1,
      organizerId: 'current_user',
      organizerName: 'You',
      date: d,
      startTime: startT,
      endTime: endT,
      participantCount: 1,
      status: EcoEventStatus.inProgress,
      createdAt: DateTime(2026, 1, 1),
      isJoined: true,
      moderationApproved: true,
    );
    final RecordingEventsRepository repo =
        RecordingEventsRepository(seed: <EcoEvent>[event]);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showExtendEventEndSheet(
                    context: context,
                    event: event,
                    eventsRepository: repo,
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save new end time'));
    await tester.pumpAndSettle();

    expect(repo.updateEventDetailsCallCount, 1);
    final DateTime expectedLocal = DateTime(
      d.year,
      d.month,
      d.day,
      endT.hour,
      endT.minute,
    ).add(const Duration(minutes: 15));
    expect(
      repo.lastUpdateEventDetailsPayload?.endAtUtc?.millisecondsSinceEpoch,
      expectedLocal.toUtc().millisecondsSinceEpoch,
    );
  });
}
