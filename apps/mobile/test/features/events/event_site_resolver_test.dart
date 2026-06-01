import 'package:feature_events/src/data/event_site_resolver.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_home/src/domain/models/cleaning_event.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/events/mock_eco_events.dart';

void main() {
  group('EventSiteSummary', () {
    test('fromEvent maps site fields', () {
      final EcoEvent event = buildMockEcoEvents().first;
      final EventSiteSummary summary = EventSiteSummary.fromEvent(event);

      expect(summary.id, event.siteId);
      expect(summary.title, event.siteName);
      expect(summary.distanceKm, event.siteDistanceKm);
      expect(summary.imageUrl, event.siteImageUrl);
    });

    test('fromPollutionSite uses first media URL or fallback asset', () {
      final PollutionSite withImage = PollutionSite(
        id: 's1',
        title: 'River site',
        description: 'Desc',
        statusLabel: 'Reported',
        statusColor: Colors.orange,
        distanceKm: 2,
        score: 1,
        participantCount: 0,
        mediaUrls: const <String>['https://cdn.example/primary.webp'],
        latitude: 41.99,
        longitude: 21.43,
      );
      final EventSiteSummary withPrimary = EventSiteSummary.fromPollutionSite(
        withImage,
      );
      expect(withPrimary.imageUrl, 'https://cdn.example/primary.webp');
      expect(withPrimary.latitude, 41.99);

      const PollutionSite noImage = PollutionSite(
        id: 's2',
        title: 'Empty',
        description: 'Desc',
        statusLabel: 'Reported',
        statusColor: Colors.orange,
        distanceKm: 1,
        score: 0,
        participantCount: 0,
        mediaUrls: <String>[],
      );
      final EventSiteSummary fallback = EventSiteSummary.fromPollutionSite(
        noImage,
      );
      expect(
        fallback.imageUrl,
        'assets/images/references/onboarding_reference.png',
      );
    });
  });

  group('EventSiteResolver.coerceSummary', () {
    test('returns null when siteId empty', () {
      expect(
        EventSiteResolver.coerceSummary(siteId: '', siteName: 'Name'),
        isNull,
      );
    });

    test('returns null when siteName missing for synthetic row', () {
      expect(
        EventSiteResolver.coerceSummary(siteId: 's1', siteName: '  '),
        isNull,
      );
    });

    test('builds synthetic summary with defaults', () {
      final EventSiteSummary? summary = EventSiteResolver.coerceSummary(
        siteId: 's9',
        siteName: ' Hidden dump ',
        siteDistanceKm: 4.2,
      );

      expect(summary?.id, 's9');
      expect(summary?.title, 'Hidden dump');
      expect(summary?.distanceKm, 4.2);
      expect(
        summary?.imageUrl,
        'assets/images/references/onboarding_reference.png',
      );
    });
  });

  group('EventSiteResolver.resolveSiteForEvent', () {
    test('uses https cover as mediaUrls', () {
      final EcoEvent event = buildMockEcoEvents().first.copyWith(
        siteImageUrl: 'https://cdn.example/cover.jpg',
      );
      final PollutionSite site = EventSiteResolver.resolveSiteForEvent(event);

      expect(site.mediaUrls, <String>['https://cdn.example/cover.jpg']);
    });

    test('uses asset path when cover is assets/', () {
      final EcoEvent event = buildMockEcoEvents().first.copyWith(
        siteImageUrl: 'assets/images/content/people_cleaning.png',
      );
      final PollutionSite site = EventSiteResolver.resolveSiteForEvent(event);

      expect(site.mediaUrls, <String>[
        'assets/images/content/people_cleaning.png',
      ]);
    });

    test('falls back to reference asset for unknown cover scheme', () {
      final EcoEvent event = buildMockEcoEvents().first.copyWith(
        siteImageUrl: 'file:///local.jpg',
      );
      final PollutionSite site = EventSiteResolver.resolveSiteForEvent(
        event,
        statusLabel: 'Upcoming',
      );

      expect(site.statusLabel, 'Upcoming');
      expect(site.mediaUrls, <String>[
        'assets/images/references/onboarding_reference.png',
      ]);
    });
  });

  group('EventSiteResolver.eventsForSite', () {
    test('filters by siteId and sorts upcoming by start time', () {
      final List<EcoEvent> all = buildMockEcoEvents();
      final List<EcoEvent> site1 = EventSiteResolver.eventsForSite(
        siteId: '1',
        events: all,
      );

      expect(site1.every((EcoEvent e) => e.siteId == '1'), isTrue);
      for (int i = 1; i < site1.length; i++) {
        expect(
          site1[i - 1].startDateTime.compareTo(site1[i].startDateTime),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('cleaningEventsForSite maps status labels', () {
      final List<CleaningEvent> rows = EventSiteResolver.cleaningEventsForSite(
        siteId: '1',
        events: buildMockEcoEvents(),
        statusLabelFor: (EcoEventStatus s) => 'label-${s.name}',
      );

      expect(rows, isNotEmpty);
      expect(rows.first.statusLabel, startsWith('label-'));
    });
  });
}
