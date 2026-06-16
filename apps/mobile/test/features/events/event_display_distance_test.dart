import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/utils/event_display_distance.dart';
import 'package:flutter_test/flutter_test.dart';

EcoEvent _event({double siteDistanceKm = 0, double? siteLat, double? siteLng}) {
  return EcoEvent(
    id: 'evt-1',
    title: 'Cleanup',
    description: 'Test',
    category: EcoEventCategory.generalCleanup,
    siteId: 'site-1',
    siteName: 'Skopje',
    siteImageUrl: '',
    siteDistanceKm: siteDistanceKm,
    siteLat: siteLat,
    siteLng: siteLng,
    organizerId: 'org-1',
    organizerName: 'Organizer',
    date: DateTime(2026, 6, 15),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 0,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime(2026, 6, 10),
  );
}

void main() {
  test('prefers server distance when siteDistanceKm is positive', () {
    final EcoEvent event = _event(
      siteDistanceKm: 2.5,
      siteLat: 41.99,
      siteLng: 21.43,
    );

    expect(
      resolveEventDisplayDistanceKm(
        event,
        userLatitude: 42,
        userLongitude: 21.5,
      ),
      2.5,
    );
  });

  test('computes haversine distance when server distance is missing', () {
    final EcoEvent event = _event(siteLat: 41.9981, siteLng: 21.4254);

    final double? km = resolveEventDisplayDistanceKm(
      event,
      userLatitude: 41.9981,
      userLongitude: 21.4254,
    );

    expect(km, isNotNull);
    expect(km, lessThan(0.01));
  });

  test('returns null when user location is unavailable', () {
    final EcoEvent event = _event(siteLat: 41.99, siteLng: 21.43);

    expect(
      resolveEventDisplayDistanceKm(
        event,
        userLatitude: null,
        userLongitude: null,
      ),
      isNull,
    );
  });

  test('returns null when site coordinates are unavailable', () {
    final EcoEvent event = _event();

    expect(
      resolveEventDisplayDistanceKm(
        event,
        userLatitude: 41.99,
        userLongitude: 21.43,
      ),
      isNull,
    );
  });
}
