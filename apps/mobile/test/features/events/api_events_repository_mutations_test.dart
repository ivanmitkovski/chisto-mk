import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_events/src/data/api_events_repository.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_join_toggle_result.dart';
import 'package:feature_events/src/domain/models/event_update_payload.dart';
import 'package:feature_events/src/domain/models/event_impact_receipt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/events/mock_eco_events.dart';

class _MutationsFakeApiClient extends ApiClient {
  _MutationsFakeApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: () {},
      );

  int getCalls = 0;
  int postCalls = 0;
  int patchCalls = 0;
  int deleteCalls = 0;
  int multipartCalls = 0;
  String? lastPatchPath;
  Object? lastPatchBody;
  String? lastPostPath;
  Object? lastPostBody;
  AppError? nextPatchError;
  AppError? nextPostError;
  AppError? nextDeleteError;
  final Map<String, ApiResponse> _getResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _postResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _patchResponses = <String, ApiResponse>{};

  void stubGet(String path, Map<String, dynamic> json) {
    _getResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  void stubPost(String path, Map<String, dynamic> json) {
    _postResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  void stubPatch(String path, Map<String, dynamic> json) {
    _patchResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    getCalls += 1;
    final ApiResponse? response = _getResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    postCalls += 1;
    lastPostPath = path;
    lastPostBody = body;
    if (nextPostError != null) {
      throw nextPostError!;
    }
    final ApiResponse? response = _postResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    patchCalls += 1;
    lastPatchPath = path;
    lastPatchBody = body;
    if (nextPatchError != null) {
      throw nextPatchError!;
    }
    final ApiResponse? response = _patchResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    deleteCalls += 1;
    if (nextDeleteError != null) {
      throw nextDeleteError!;
    }
    return const ApiResponse(statusCode: 204, json: null);
  }

  @override
  Future<ApiResponse> postMultipart(
    String path,
    List<String> filePaths, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    multipartCalls += 1;
    return const ApiResponse(statusCode: 200, json: null);
  }
}

Map<String, dynamic> _eventJsonFromEco(EcoEvent event) {
  return <String, dynamic>{
    'id': event.id,
    'title': event.title,
    'description': event.description,
    'category': event.category.name,
    'siteId': event.siteId,
    'siteName': event.siteName,
    'siteImageUrl': event.siteImageUrl,
    'organizerId': event.organizerId,
    'organizerName': event.organizerName,
    'scheduledAt':
        event.scheduledAtUtc?.toIso8601String() ??
        event.startDateTime.toUtc().toIso8601String(),
    'endAt': event.endDateTime.toUtc().toIso8601String(),
    'status': event.status.name,
    'participantCount': event.participantCount,
    'createdAt': event.createdAt.toIso8601String(),
    'gear': event.gear.map((EventGear g) => g.name).toList(),
    'isCheckInOpen': event.isCheckInOpen,
    'checkedInCount': event.checkedInCount,
    'isJoined': event.isJoined,
    'maxParticipants': event.maxParticipants,
    'moderationApproved': event.moderationApproved,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ApiEventsRepository mutations', () {
    late _MutationsFakeApiClient client;
    late ApiEventsRepository repo;
    late EcoEvent seedEvent;

    setUp(() async {
      client = _MutationsFakeApiClient();
      repo = ApiEventsRepository(client: client);
      seedEvent = buildMockEcoEvents().first;
      client.stubGet('/events?limit=50', <String, dynamic>{
        'data': <dynamic>[_eventJsonFromEco(seedEvent)],
        'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
      });
      repo.loadInitialIfNeeded();
      await repo.ready;
    });

    test('create POSTs body and upserts returned event', () async {
      final EcoEvent draft = EcoEvent(
        id: 'evt-new',
        title: 'Brand new cleanup',
        description: seedEvent.description,
        category: seedEvent.category,
        siteId: seedEvent.siteId,
        siteName: seedEvent.siteName,
        siteImageUrl: seedEvent.siteImageUrl,
        siteDistanceKm: seedEvent.siteDistanceKm,
        organizerId: seedEvent.organizerId,
        organizerName: seedEvent.organizerName,
        date: seedEvent.date,
        startTime: seedEvent.startTime,
        endTime: seedEvent.endTime,
        participantCount: 0,
        status: EcoEventStatus.upcoming,
        createdAt: seedEvent.createdAt,
      );
      client.stubPost('/events', _eventJsonFromEco(draft));

      final EcoEvent created = await repo.create(draft);

      expect(created.id, 'evt-new');
      expect(repo.findById('evt-new')?.title, 'Brand new cleanup');
      expect(client.postCalls, 1);
    });

    test('updateEventDetails with empty payload returns existing', () async {
      final EcoEvent existing = await repo.updateEventDetails(
        seedEvent.id,
        const EventUpdatePayload(),
      );
      expect(existing.id, seedEvent.id);
      expect(client.patchCalls, 0);
    });

    test('updateEventDetails PATCHes and refreshes store', () async {
      final EcoEvent updated = seedEvent.copyWith(title: 'Renamed');
      client.stubPatch('/events/${seedEvent.id}', _eventJsonFromEco(updated));

      final EcoEvent result = await repo.updateEventDetails(
        seedEvent.id,
        const EventUpdatePayload(title: 'Renamed'),
      );

      expect(result.title, 'Renamed');
      expect(repo.findById(seedEvent.id)?.title, 'Renamed');
      expect(client.lastPatchPath, '/events/${seedEvent.id}');
    });

    test('updateEventDetails throws when event missing from store', () async {
      await expectLater(
        repo.updateEventDetails(
          'missing',
          const EventUpdatePayload(title: 'X'),
        ),
        throwsA(isA<AppError>()),
      );
    });

    test('checkScheduleConflict GETs query params', () async {
      client.stubGet(
        '/events/check-conflict?siteId=site-1&scheduledAt=2026-08-15T09%3A30%3A00.000Z&excludeEventId=evt-x',
        <String, dynamic>{
          'hasConflict': true,
          'conflictingEvent': <String, dynamic>{
            'id': 'evt-other',
            'title': 'Overlap',
            'scheduledAt': '2026-08-15T10:00:00.000Z',
          },
        },
      );

      final preview = await repo.checkScheduleConflict(
        siteId: 'site-1',
        scheduledAt: DateTime.utc(2026, 8, 15, 9, 30),
        excludeEventId: 'evt-x',
      );

      expect(preview.hasConflict, isTrue);
      expect(preview.conflictingEvent?.id, 'evt-other');
    });

    test('updateStatus optimistic then refreshes from server', () async {
      client.stubPatch('/events/${seedEvent.id}/status', <String, dynamic>{
        'status': 'inProgress',
      });
      final EcoEvent inProgress = seedEvent.copyWith(
        status: EcoEventStatus.inProgress,
      );
      client.stubGet('/events/${seedEvent.id}', _eventJsonFromEco(inProgress));

      final bool ok = await repo.updateStatus(
        seedEvent.id,
        EcoEventStatus.inProgress,
      );

      expect(ok, isTrue);
      expect(repo.findById(seedEvent.id)?.status, EcoEventStatus.inProgress);
    });

    test('updateStatus rolls back on AppError', () async {
      client.nextPatchError = const AppError(code: 'SERVER', message: 'fail');

      await expectLater(
        repo.updateStatus(seedEvent.id, EcoEventStatus.inProgress),
        throwsA(isA<AppError>()),
      );
      expect(repo.findById(seedEvent.id)?.status, seedEvent.status);
    });

    test('updateStatus returns false for invalid transition', () async {
      final bool ok = await repo.updateStatus(
        seedEvent.id,
        EcoEventStatus.completed,
      );
      expect(ok, isFalse);
      expect(client.patchCalls, 0);
    });

    test('toggleJoin join awards points from POST response', () async {
      final EcoEvent volunteerEvent = buildMockEcoEvents()[1].copyWith(
        isJoined: false,
      );
      client.stubGet('/events?limit=50', <String, dynamic>{
        'data': <dynamic>[_eventJsonFromEco(volunteerEvent)],
        'meta': <String, dynamic>{'hasMore': false},
      });
      final ApiEventsRepository joinRepo = ApiEventsRepository(client: client);
      joinRepo.loadInitialIfNeeded();
      await joinRepo.ready;

      client.stubPost('/events/${volunteerEvent.id}/join', <String, dynamic>{
        'pointsAwarded': 25,
      });
      final EcoEvent joined = volunteerEvent.copyWith(isJoined: true);
      client.stubGet('/events/${volunteerEvent.id}', _eventJsonFromEco(joined));

      final EcoEventJoinToggleResult result = await joinRepo.toggleJoin(
        volunteerEvent.id,
      );

      expect(result.changed, isTrue);
      expect(result.pointsAwarded, 25);
      expect(client.postCalls, 1);
    });

    test('toggleJoin leave DELETEs join endpoint', () async {
      final EcoEvent volunteerEvent = buildMockEcoEvents()[1].copyWith(
        isJoined: true,
      );
      client.stubGet('/events?limit=50', <String, dynamic>{
        'data': <dynamic>[_eventJsonFromEco(volunteerEvent)],
        'meta': <String, dynamic>{'hasMore': false},
      });
      final ApiEventsRepository leaveRepo = ApiEventsRepository(client: client);
      leaveRepo.loadInitialIfNeeded();
      await leaveRepo.ready;

      final EcoEvent left = volunteerEvent.copyWith(isJoined: false);
      client.stubGet('/events/${volunteerEvent.id}', _eventJsonFromEco(left));

      final EcoEventJoinToggleResult result = await leaveRepo.toggleJoin(
        volunteerEvent.id,
      );

      expect(result.changed, isTrue);
      expect(client.deleteCalls, 1);
    });

    test('toggleJoin no-op when event at capacity', () async {
      final EcoEvent full = seedEvent.copyWith(
        isJoined: false,
        maxParticipants: 5,
        participantCount: 5,
      );
      client.stubGet('/events?limit=50', <String, dynamic>{
        'data': <dynamic>[_eventJsonFromEco(full)],
        'meta': <String, dynamic>{'hasMore': false},
      });
      final ApiEventsRepository fullRepo = ApiEventsRepository(client: client);
      fullRepo.loadInitialIfNeeded();
      await fullRepo.ready;

      final EcoEventJoinToggleResult result = await fullRepo.toggleJoin(
        full.id,
      );

      expect(result.changed, isFalse);
      expect(client.postCalls, 0);
    });

    test('setReminder PATCHes and refreshes event', () async {
      final DateTime reminderAt = DateTime.utc(2026, 8, 14, 8, 0);
      client.stubPatch('/events/${seedEvent.id}/reminder', <String, dynamic>{});
      final EcoEvent withReminder = seedEvent.copyWith(
        reminderEnabled: true,
        reminderAt: reminderAt,
      );
      client.stubGet(
        '/events/${seedEvent.id}',
        _eventJsonFromEco(withReminder),
      );

      final bool ok = await repo.setReminder(
        eventId: seedEvent.id,
        enabled: true,
        reminderAt: reminderAt,
      );

      expect(ok, isTrue);
      expect(client.lastPatchPath, '/events/${seedEvent.id}/reminder');
    });

    test('fetchImpactReceipt parses receipt JSON', () async {
      client
          .stubGet('/events/${seedEvent.id}/impact-receipt', <String, dynamic>{
            'eventId': seedEvent.id,
            'title': seedEvent.title,
            'siteLabel': seedEvent.siteName,
            'scheduledAt': '2026-06-15T09:30:00.000Z',
            'endAt': '2026-06-15T11:45:00.000Z',
            'lifecycleStatus': 'completed',
            'participantCount': 8,
            'checkedInCount': 7,
            'reportedBagsCollected': 12,
            'bagsUpdatedAt': '2026-06-15T12:00:00.000Z',
            'evidence': <dynamic>[],
            'afterImageUrls': <String>[],
            'completeness': 'full',
            'asOf': '2026-06-15T12:05:00.000Z',
            'organizerName': seedEvent.organizerName,
          });

      final EventImpactReceipt receipt = await repo.fetchImpactReceipt(
        seedEvent.id,
      );

      expect(receipt.reportedBagsCollected, 12);
      expect(receipt.checkedInCount, 7);
    });

    test('pushLiveImpactBags returns true on 2xx', () async {
      client.stubPatch(
        '/events/${seedEvent.id}/live-impact',
        <String, dynamic>{},
      );

      expect(await repo.pushLiveImpactBags(seedEvent.id, 4), isTrue);
      expect(client.lastPatchPath, '/events/${seedEvent.id}/live-impact');
    });

    test('local check-in helpers update in-memory event', () {
      expect(repo.setCheckInOpen(eventId: seedEvent.id, isOpen: true), isTrue);
      expect(
        repo.rotateCheckInSession(eventId: seedEvent.id, sessionId: 'sess-2'),
        isTrue,
      );
      expect(
        repo.setCheckedInCount(eventId: seedEvent.id, checkedInCount: 3),
        isTrue,
      );
      expect(
        repo.setAttendeeCheckInStatus(
          eventId: seedEvent.id,
          status: AttendeeCheckInStatus.checkedIn,
          checkedInAt: DateTime.utc(2026, 6, 15, 10),
        ),
        isTrue,
      );
      final EcoEvent? updated = repo.findById(seedEvent.id);
      expect(updated?.checkedInCount, 3);
      expect(updated?.attendeeCheckInStatus, AttendeeCheckInStatus.checkedIn);
    });
  });
}
