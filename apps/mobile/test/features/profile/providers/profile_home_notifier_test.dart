import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/profile/data/profile_me_json.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_home_notifier.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/testing_profile_repository.dart';
import '../support/testing_reports_api_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  group('ProfileHomeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      ServiceLocator.instance.authState.setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't',
      );
      final ReportCapacity capacity = ReportCapacity(
        creditsAvailable: 1,
        emergencyAvailable: false,
        emergencyWindowDays: 7,
        retryAfterSeconds: null,
        nextEmergencyReportAvailableAt: null,
        nextRefillAtMs: null,
        unlockHint: '',
      );
      container = ProviderContainer(
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            TestingProfileRepository(
              getMeImpl: () async => profileUserFromMeJson(<String, dynamic>{
                'id': 'u1',
                'firstName': 'T',
                'lastName': 'E',
                'email': 't@e.st',
                'phoneNumber': '+1',
                'pointsBalance': 1,
                'totalPointsEarned': 2,
                'level': 1,
                'levelProgress': 0,
                'pointsInLevel': 0,
                'pointsToNextLevel': 10,
                'weeklyPoints': 0,
                'weeklyRank': null,
                'weekStartsAt': '',
                'weekEndsAt': '',
              }),
            ),
          ),
          reportsApiRepositoryProvider.overrideWithValue(
            TestingReportsApiRepository(
              getReportingCapacityImpl: () async => capacity,
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      ServiceLocator.instance.authState.setUnauthenticated();
    });

    test('loadProfile sets user when authenticated', () async {
      await container.read(profileHomeNotifierProvider.notifier).loadProfile();
      final ProfileHomeState s = container.read(profileHomeNotifierProvider);
      expect(s.profileUser, isNotNull);
      expect(s.profileUser!.id, 'u1');
      expect(s.profileLoadError, isNull);
      expect(s.capacityLoadInFlight, isFalse);
    });
  });
}
