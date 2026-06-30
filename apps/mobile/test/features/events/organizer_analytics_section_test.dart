import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_analytics.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/organizer_analytics_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

EcoEvent _testEvent({String id = 'evt-1'}) {
  return EcoEvent(
    id: id,
    title: 'River cleanup',
    description: 'D',
    category: EcoEventCategory.riverAndLake,
    siteId: 's1',
    siteName: 'Site',
    siteImageUrl: '',
    siteDistanceKm: 1,
    organizerId: 'org-1',
    organizerName: 'Org',
    date: DateTime.utc(2026, 6, 15),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 3,
    status: EcoEventStatus.completed,
    createdAt: DateTime.utc(2026, 6, 1),
  );
}

List<CheckInsByHourEntry> _zeros24() {
  return List<CheckInsByHourEntry>.generate(
    24,
    (int h) => CheckInsByHourEntry(hour: h, count: 0),
    growable: false,
  );
}

Widget _app(Widget child) {
  return wrapForWidgetTest(
    MediaQuery(
      data: const MediaQueryData(size: Size(400, 900)),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows joiners empty caption when there are no joins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OrganizerAnalyticsSection(
          event: _testEvent(),
          fetchAnalytics: (_) async => EventAnalytics(
            totalJoiners: 0,
            checkedInCount: 0,
            attendanceRate: 0,
            joinersCumulative: const <JoinersCumulativeEntry>[],
            checkInsByHour: _zeros24(),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('No one has joined this event yet.'), findsOneWidget);
    expect(
      find.text('No check-ins yet. Hours are shown in UTC.'),
      findsOneWidget,
    );
  });

  testWidgets('shows cumulative join chart for a single joiner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OrganizerAnalyticsSection(
          event: _testEvent(),
          fetchAnalytics: (_) async => EventAnalytics(
            totalJoiners: 1,
            checkedInCount: 0,
            attendanceRate: 0,
            joinersCumulative: <JoinersCumulativeEntry>[
              JoinersCumulativeEntry(
                at: DateTime.utc(2026, 6, 10, 9, 0),
                cumulativeJoiners: 1,
              ),
            ],
            checkInsByHour: _zeros24(),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('No one has joined this event yet.'), findsNothing);
  });

  testWidgets('shows peak UTC label when check-ins exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OrganizerAnalyticsSection(
          event: _testEvent(),
          fetchAnalytics: (_) async {
            return EventAnalytics(
              totalJoiners: 2,
              checkedInCount: 2,
              attendanceRate: 100,
              joinersCumulative: <JoinersCumulativeEntry>[
                JoinersCumulativeEntry(
                  at: DateTime.utc(2026, 6, 10, 8, 0),
                  cumulativeJoiners: 1,
                ),
                JoinersCumulativeEntry(
                  at: DateTime.utc(2026, 6, 10, 9, 0),
                  cumulativeJoiners: 2,
                ),
              ],
              checkInsByHour: List<CheckInsByHourEntry>.generate(
                24,
                (int h) => CheckInsByHourEntry(hour: h, count: h == 14 ? 3 : 0),
                growable: false,
              ),
            );
          },
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Peak: 14:00 UTC'), findsOneWidget);
    expect(find.text('2 of 2 checked in'), findsOneWidget);
    expect(find.text('Joined 2'), findsOneWidget);
    expect(find.text('Checked in 2'), findsOneWidget);
    expect(find.text('Pending 0'), findsOneWidget);
    expect(find.text('3 total check-ins recorded'), findsOneWidget);
    expect(find.text('Check-ins 3'), findsOneWidget);
  });

  testWidgets('does not wrap analytics in detailModule card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OrganizerAnalyticsSection(
          event: _testEvent(),
          fetchAnalytics: (_) async => EventAnalytics(
            totalJoiners: 1,
            checkedInCount: 0,
            attendanceRate: 0,
            joinersCumulative: const <JoinersCumulativeEntry>[],
            checkInsByHour: _zeros24(),
          ),
        ),
      ),
    );
    await _settle(tester);

    final Finder decorated = find.byWidgetPredicate(
      (Widget w) =>
          w is DecoratedBox &&
          w.decoration == EventDetailSurfaceDecoration.detailModule(),
    );
    expect(decorated, findsNothing);
  });

  testWidgets('shows Live pill when event is in progress', (
    WidgetTester tester,
  ) async {
    final EcoEvent live = _testEvent().copyWith(
      status: EcoEventStatus.inProgress,
    );
    await tester.pumpWidget(
      _app(
        OrganizerAnalyticsSection(
          event: live,
          fetchAnalytics: (_) async => EventAnalytics(
            totalJoiners: 0,
            checkedInCount: 0,
            attendanceRate: 0,
            joinersCumulative: const <JoinersCumulativeEntry>[],
            checkInsByHour: _zeros24(),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Live'), findsOneWidget);
  });
}
