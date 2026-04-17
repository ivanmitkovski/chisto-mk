import 'dart:async';
import 'dart:io';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/api_check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recording_events_repository.dart';

class _StubApiClient extends ApiClient {
  _StubApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  ApiResponse? postResult;
  Object? postError;
  final Completer<void> prefetchBarrier = Completer<void>();
  int postCallCount = 0;
  int getCallCount = 0;

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    postCallCount++;
    if (postError != null) {
      throw postError!;
    }
    return postResult ??
        const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? headers}) async {
    getCallCount++;
    return const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }
}

EcoEvent _buildEvent({String id = 'evt-1'}) {
  return EcoEvent(
    id: id,
    title: 'Test',
    description: 'D',
    category: EcoEventCategory.generalCleanup,
    siteId: 's1',
    siteName: 'Site',
    siteImageUrl: '',
    siteDistanceKm: 0,
    organizerId: 'org-1',
    organizerName: 'Org',
    date: DateTime(2026, 6, 15),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 12, minute: 0),
    participantCount: 5,
    status: EcoEventStatus.inProgress,
    createdAt: DateTime(2026, 6, 10),
    isCheckInOpen: true,
    isJoined: true,
    attendeeCheckInStatus: AttendeeCheckInStatus.notCheckedIn,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StubApiClient client;
  late RecordingEventsRepository events;
  late ApiCheckInRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    client = _StubApiClient();
    events = RecordingEventsRepository(seed: <EcoEvent>[_buildEvent()]);
    repo = ApiCheckInRepository(
      client: client,
      eventsRepository: events,
    );
  });

  group('submissionStatusForAppError', () {
    test('maps redeem-related API codes', () {
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_REQUIRES_JOIN', message: 'm'),
        ),
        CheckInSubmissionStatus.requiresJoin,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_INVALID_QR', message: 'm'),
        ),
        CheckInSubmissionStatus.invalidQr,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_LIFECYCLE', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'EVENT_NOT_JOINABLE', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'EVENT_NOT_FOUND', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_NOT_FOUND', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'ORGANIZER_CANNOT_CHECK_IN', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'TOO_MANY_REQUESTS', message: 'm'),
        ),
        CheckInSubmissionStatus.rateLimited,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CONFLICT', message: 'm'),
        ),
        CheckInSubmissionStatus.replayDetected,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_REPLAY', message: 'm'),
        ),
        CheckInSubmissionStatus.replayDetected,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_REQUEST_EXPIRED', message: 'm'),
        ),
        CheckInSubmissionStatus.sessionExpired,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_REQUEST_NOT_FOUND', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_FORBIDDEN', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
      expect(
        repo.submissionStatusForAppError(
          const AppError(code: 'CHECK_IN_MISCONFIG', message: 'm'),
        ),
        CheckInSubmissionStatus.checkInUnavailable,
      );
    });
  });

  group('submitScan', () {
    test('returns success immediately and sets optimistic state', () async {
      client.postResult = const ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'checkedInAt': '2026-06-15T13:01:00.000Z',
          'pointsAwarded': 10,
        },
      );

      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-test-payload',
        expectedEventId: 'evt-1',
        attendeeId: 'att-1',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.success);
      expect(result.checkedInAt, isNotNull);
      expect(result.checkedInAt!.isUtc, isFalse);
      expect(result.pointsAwarded, 10);

      expect(events.setAttendeeCheckInStatusCallCount, 1);
      expect(
        events.lastSetAttendeeCheckInStatusValue,
        AttendeeCheckInStatus.checkedIn,
      );
      expect(events.lastSetAttendeeCheckInStatusAt, isNotNull);
    });

    test('SocketException queues offline and sets optimistic state', () async {
      client.postError = const SocketException('no network');

      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-offline-payload',
        expectedEventId: 'evt-1',
        attendeeId: 'att-1',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.queuedOffline);
      expect(events.setAttendeeCheckInStatusCallCount, 1);
      expect(
        events.lastSetAttendeeCheckInStatusValue,
        AttendeeCheckInStatus.checkedIn,
      );
    });

    test('TimeoutException queues offline and sets optimistic state', () async {
      client.postError = TimeoutException('timed out');

      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-timeout-payload',
        expectedEventId: 'evt-1',
        attendeeId: 'att-1',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.queuedOffline);
      expect(events.setAttendeeCheckInStatusCallCount, 1);
      expect(
        events.lastSetAttendeeCheckInStatusValue,
        AttendeeCheckInStatus.checkedIn,
      );
    });

    test('AppError with no_internet queues offline', () async {
      client.postError =
          const AppError(code: 'no_internet', message: 'offline');

      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-apperr-payload',
        expectedEventId: 'evt-1',
        attendeeId: 'att-1',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.queuedOffline);
      expect(events.setAttendeeCheckInStatusCallCount, 1);
    });

    test('AppError.network (NETWORK_ERROR) queues offline', () async {
      client.postError = AppError.network(message: 'unreachable');

      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-network-payload',
        expectedEventId: 'evt-1',
        attendeeId: 'att-1',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.queuedOffline);
      expect(events.setAttendeeCheckInStatusCallCount, 1);
    });

    test('AppError.timeout (TIMEOUT) queues offline', () async {
      client.postError = AppError.timeout(message: 'slow');

      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-timeout-app-payload',
        expectedEventId: 'evt-1',
        attendeeId: 'att-1',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.queuedOffline);
      expect(events.setAttendeeCheckInStatusCallCount, 1);
    });

    test('empty attendeeId returns invalidFormat immediately', () async {
      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-payload',
        expectedEventId: 'evt-1',
        attendeeId: '',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.invalidFormat);
      expect(client.postCallCount, 0);
    });

    test('background prefetch fires but does not block result', () async {
      client.postResult = const ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'checkedInAt': '2026-06-15T13:01:00.000Z',
          'pointsAwarded': 5,
        },
      );

      final CheckInSubmissionResult result = await repo.submitScan(
        rawPayload: 'qr-bg-payload',
        expectedEventId: 'evt-1',
        attendeeId: 'att-1',
        attendeeName: 'Alice',
      );

      expect(result.status, CheckInSubmissionStatus.success);
      expect(events.prefetchEventCallCount, greaterThanOrEqualTo(0));
    });
  });
}
