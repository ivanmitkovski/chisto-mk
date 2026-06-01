import 'package:feature_events/src/data/check_in_local_cache.dart';
import 'package:feature_events/src/domain/models/check_in_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const CheckInLocalCache cache = CheckInLocalCache();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('readSessions returns empty when unset', () async {
    expect(await cache.readSessions(), isEmpty);
  });

  test('writeSessions round-trips attendees', () async {
    await cache.writeSessions(<PersistedCheckInSession>[
      PersistedCheckInSession(
        eventId: 'evt-1',
        sessionId: 'sess-1',
        isOpen: true,
        attendees: <CheckedInAttendee>[
          CheckedInAttendee(
            id: 'u1',
            name: 'Ana K',
            checkedInAt: DateTime.utc(2026, 6, 15, 10),
            userId: 'u1',
          ),
        ],
      ),
    ]);
    final List<PersistedCheckInSession> loaded = await cache.readSessions();

    expect(loaded, hasLength(1));
    expect(loaded.single.eventId, 'evt-1');
    expect(loaded.single.attendees.single.name, 'Ana K');
  });

  test('readSessions ignores corrupt JSON', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'events_checkin_sessions_v1': '{not-json',
    });
    expect(await cache.readSessions(), isEmpty);
  });

  test('readSessions skips invalid session rows', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'events_checkin_sessions_v1':
          '[{"eventId":"","sessionId":""},{"eventId":"e1","sessionId":"s1","isOpen":false,"attendees":[]}]',
    });
    final List<PersistedCheckInSession> loaded = await cache.readSessions();
    expect(loaded, hasLength(1));
    expect(loaded.single.eventId, 'e1');
  });

  test('clear removes persisted sessions', () async {
    await cache.writeSessions(<PersistedCheckInSession>[
      const PersistedCheckInSession(
        eventId: 'evt-1',
        sessionId: 'sess-1',
        isOpen: false,
        attendees: <CheckedInAttendee>[],
      ),
    ]);
    await cache.clear();
    expect(await cache.readSessions(), isEmpty);
  });

  group('PersistedCheckInSession.fromJson', () {
    test('returns null when ids missing', () {
      expect(PersistedCheckInSession.fromJson(<String, dynamic>{}), isNull);
    });

    test('parses attendee list', () {
      final PersistedCheckInSession? session = PersistedCheckInSession.fromJson(
        <String, dynamic>{
          'eventId': 'e1',
          'sessionId': 's1',
          'isOpen': true,
          'attendees': <dynamic>[
            <String, dynamic>{'id': 'u1', 'name': 'Test', 'checkedInAt': 1},
          ],
        },
      );
      expect(session?.attendees, hasLength(1));
    });
  });
}
