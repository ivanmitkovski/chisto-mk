import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/api_check_in_repository.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubApiClient extends ApiClient {
  _StubApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiCheckInRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final InMemoryEventsStore events = InMemoryEventsStore.instance;
    events.resetToSeed();
    repo = ApiCheckInRepository(
      client: _StubApiClient(),
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
    });
  });
}
