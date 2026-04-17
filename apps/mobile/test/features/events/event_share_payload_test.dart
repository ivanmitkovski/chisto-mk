import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_share_payload.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('eventShareHttpsUri', () {
    test('returns https Uri for normal base', () {
      final Uri? u = eventShareHttpsUri('https://chisto.mk', 'evt-1');
      expect(u, isNotNull);
      expect(u!.toString(), 'https://chisto.mk/events/evt-1');
    });

    test('strips trailing slash on base', () {
      final Uri? u = eventShareHttpsUri('https://staging.chisto.mk/', 'abc');
      expect(u!.toString(), 'https://staging.chisto.mk/events/abc');
    });

    test('returns null for http base', () {
      expect(eventShareHttpsUri('http://insecure.example', 'id'), isNull);
    });
  });

  group('eventSharePageUrl', () {
    test('joins base and id', () {
      expect(
        eventSharePageUrl('https://chisto.mk', 'x'),
        'https://chisto.mk/events/x',
      );
    });
  });

  group('buildEventSharePlainText', () {
    testWidgets('includes title site and https link line', (WidgetTester tester) async {
      final EcoEvent event = EcoEvent(
        id: 'event-share-test',
        title: 'River day',
        description: 'D',
        category: EcoEventCategory.generalCleanup,
        siteId: 's',
        siteName: 'Site A',
        siteImageUrl: '',
        siteDistanceKm: 1,
        organizerId: 'o',
        organizerName: 'Org',
        date: DateTime.utc(2026, 4, 16),
        startTime: const EventTime(hour: 9, minute: 0),
        endTime: const EventTime(hour: 11, minute: 0),
        participantCount: 0,
        status: EcoEventStatus.upcoming,
        createdAt: DateTime.utc(2026, 4, 1),
      );
      late String built;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              built = buildEventSharePlainText(
                context,
                event,
                'https://example.com/',
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(built, contains('River day'));
      expect(built, contains('Site A'));
      expect(built, endsWith('https://example.com/events/event-share-test'));
      expect(built.contains('\n\n'), isTrue);
    });
  });
}
