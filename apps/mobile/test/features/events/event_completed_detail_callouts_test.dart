import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_completed_detail_callouts.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EcoEvent _base({
  required EcoEventStatus status,
  required String organizerId,
  bool isJoined = false,
  List<String> afterImagePaths = const <String>[],
}) {
  return EcoEvent(
    id: 'e1',
    title: 'Cleanup',
    description: 'd',
    category: EcoEventCategory.generalCleanup,
    siteId: '1',
    siteName: 'Site',
    siteImageUrl: 'assets/test.png',
    siteDistanceKm: 1,
    organizerId: organizerId,
    organizerName: 'Org',
    date: DateTime(2025, 6, 1),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 11, minute: 0),
    participantCount: 3,
    status: status,
    createdAt: DateTime(2025, 5, 1),
    isJoined: isJoined,
    afterImagePaths: afterImagePaths,
  );
}

void main() {
  testWidgets('organizer completed without photos shows pending banner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: EventCompletedDetailCallouts(
            event: _base(
              status: EcoEventStatus.completed,
              organizerId: 'current_user',
            ),
          ),
        ),
      ),
    );

    expect(find.text('After photos'), findsOneWidget);
    expect(find.textContaining('Upload photos after cleanup'), findsOneWidget);
  });

  testWidgets('joined attendee completed shows thank you card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: EventCompletedDetailCallouts(
            event: _base(
              status: EcoEventStatus.completed,
              organizerId: 'other_user',
              isJoined: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Thank you'), findsOneWidget);
    expect(find.textContaining('complete'), findsOneWidget);
  });
}
