import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/organizer_dashboard/organizer_event_summary_card.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EcoEvent baseEvent({required bool moderationApproved}) {
    return EcoEvent(
      id: 'evt-1',
      title: 'Cleaning of vardar',
      description: 'D',
      category: EcoEventCategory.generalCleanup,
      siteId: 's1',
      siteName: 'Makedonija 1, Skopje',
      siteImageUrl: '',
      siteDistanceKm: 0,
      organizerId: 'org-1',
      organizerName: 'Org',
      date: DateTime(2026, 4, 18),
      startTime: const EventTime(hour: 10, minute: 0),
      endTime: const EventTime(hour: 12, minute: 0),
      participantCount: 0,
      status: EcoEventStatus.upcoming,
      createdAt: DateTime(2026, 4, 17),
      moderationApproved: moderationApproved,
    );
  }

  testWidgets('hides Check-in when event is not moderation-approved', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: OrganizerEventSummaryCard(
            event: baseEvent(moderationApproved: false),
            onTap: () {},
            onCheckIn: () {},
            onEvidence: () {},
          ),
        ),
      ),
    );

    expect(find.text('Check-in'), findsNothing);
  });

  testWidgets('shows Check-in when event is moderation-approved', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: OrganizerEventSummaryCard(
            event: baseEvent(moderationApproved: true),
            onTap: () {},
            onCheckIn: () {},
            onEvidence: () {},
          ),
        ),
      ),
    );

    expect(find.text('Check-in'), findsOneWidget);
  });
}
