import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_button.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/cleaning_events_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../events/recording_events_repository.dart';
import '../support/test_pollution_site.dart';

EcoEvent _siteEvent({required String siteId, required bool isJoined}) {
  return EcoEvent(
    id: 'event-1',
    title: 'Clean it',
    description: 'Desc',
    category: EcoEventCategory.generalCleanup,
    siteId: siteId,
    siteName: 'Site',
    siteImageUrl: '',
    siteDistanceKm: 1,
    organizerId: 'other-organizer',
    organizerName: 'Org',
    date: DateTime(2026, 5, 27),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 1,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime(2026, 5, 1),
    isJoined: isJoined,
    moderationApproved: true,
  );
}

void main() {
  tearDown(() {
    setEventsRepositoryTestOverride(null);
  });

  testWidgets('shows Join action when user has not joined', (
    WidgetTester tester,
  ) async {
    setEventsRepositoryTestOverride(
      RecordingEventsRepository(
        seed: <EcoEvent>[_siteEvent(siteId: 'site-1', isJoined: false)],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: CleaningEventsTab(
              site: buildTestPollutionSite(id: 'site-1'),
              onCreateEvent: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Join action'), findsOneWidget);
    expect(find.text('Joined'), findsNothing);
  });

  testWidgets('shows disabled Joined when user already joined', (
    WidgetTester tester,
  ) async {
    setEventsRepositoryTestOverride(
      RecordingEventsRepository(
        seed: <EcoEvent>[_siteEvent(siteId: 'site-1', isJoined: true)],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: CleaningEventsTab(
              site: buildTestPollutionSite(id: 'site-1'),
              onCreateEvent: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Joined'), findsOneWidget);
    expect(find.text('Join action'), findsNothing);

    final AppButton joinedButton = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Joined'),
    );
    expect(joinedButton.enabled, isFalse);
  });
}
