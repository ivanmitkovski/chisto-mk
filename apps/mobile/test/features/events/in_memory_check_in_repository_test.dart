import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_check_in_repository.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late InMemoryEventsStore eventsStore;
  late InMemoryCheckInRepository checkInRepository;
  late EcoEvent event;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    eventsStore = InMemoryEventsStore.instance;
    EventsRepositoryRegistry.setTestOverride(eventsStore);
    checkInRepository = InMemoryCheckInRepository.instance;
    checkInRepository.reset();
    eventsStore.resetToSeed();

    event = EcoEvent(
      id: 'evt-test-checkin',
      title: 'Check-in test event',
      description: 'Testing check-in',
      category: EcoEventCategory.generalCleanup,
      siteId: 'site-test',
      siteName: 'Test site',
      siteImageUrl: 'assets/images/references/onboarding_reference.png',
      siteDistanceKm: 1.5,
      organizerId: 'current_user',
      organizerName: 'You',
      date: DateTime.now(),
      startTime: const EventTime(hour: 10, minute: 0),
      endTime: const EventTime(hour: 12, minute: 0),
      participantCount: 3,
      status: EcoEventStatus.inProgress,
      createdAt: DateTime.now(),
      isJoined: true,
    );
    await eventsStore.create(event);
    await checkInRepository.ensureSession(event: event);
  });

  tearDown(() {
    EventsRepositoryRegistry.setTestOverride(null);
  });

  test('valid scan succeeds and replay is blocked', () async {
    final CheckInQrPayload payload =
        await checkInRepository.issuePayload(eventId: event.id);

    final CheckInSubmissionResult first = await checkInRepository.submitScan(
      rawPayload: payload.encode(),
      expectedEventId: event.id,
      attendeeId: 'user-a',
      attendeeName: 'User A',
    );
    expect(first.status, equals(CheckInSubmissionStatus.success));

    final CheckInSubmissionResult replay = await checkInRepository.submitScan(
      rawPayload: payload.encode(),
      expectedEventId: event.id,
      attendeeId: 'user-a',
      attendeeName: 'User A',
    );
    expect(replay.status, equals(CheckInSubmissionStatus.replayDetected));
  });

  test('duplicate attendee check-in is rejected', () async {
    final CheckInQrPayload firstPayload =
        await checkInRepository.issuePayload(eventId: event.id);
    final CheckInSubmissionResult first = await checkInRepository.submitScan(
      rawPayload: firstPayload.encode(),
      expectedEventId: event.id,
      attendeeId: 'user-b',
      attendeeName: 'User B',
    );
    expect(first.isSuccess, isTrue);

    final CheckInQrPayload secondPayload =
        await checkInRepository.issuePayload(eventId: event.id);
    final CheckInSubmissionResult second = await checkInRepository.submitScan(
      rawPayload: secondPayload.encode(),
      expectedEventId: event.id,
      attendeeId: 'user-b',
      attendeeName: 'User B',
    );
    expect(second.status, equals(CheckInSubmissionStatus.alreadyCheckedIn));
  });

  test('persists session roster and exposes live QR ttl', () async {
    expect(
      checkInRepository.payloadTtl,
      equals(const Duration(milliseconds: 45000)),
    );

    final ManualCheckInResult added = await checkInRepository.markAttendeeCheckedIn(
      eventId: event.id,
      attendeeId: 'in_memory_volunteer_0',
      attendeeName: 'Volunteer 1',
    );

    expect(added.recorded, isTrue);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('events_checkin_sessions_v1');

    expect(raw, isNotNull);
    expect(raw, contains(event.id));
    expect(raw, contains('Volunteer 1'));
  });
}
