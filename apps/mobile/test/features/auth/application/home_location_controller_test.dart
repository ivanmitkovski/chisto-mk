import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/application/home_location_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_feature_guide_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('saveHomeLocation succeeds', () async {
    var saved = false;
    final FakeAuthRepository repo = FakeAuthRepository(
      updateHomeLocationImpl: ({
        required double latitude,
        required double longitude,
        String? label,
      }) async {
        saved = true;
        expect(latitude, 41.6);
        expect(longitude, 21.7);
      },
    );
    final FakeFeatureGuideRepository guide = FakeFeatureGuideRepository();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...AuthTestOverrides(
          authRepository: repo,
          featureGuideRepository: guide,
        ).build(),
      ],
    );
    addTearDown(container.dispose);

    await container.read(homeLocationControllerProvider.notifier).saveHomeLocation(
          latitude: 41.6,
          longitude: 21.7,
          label: 'Skopje',
        );

    expect(saved, isTrue);
    expect(guide.postRegistrationPending, isTrue);
    expect(container.read(homeLocationControllerProvider).isLoading, isFalse);
  });

  test('saveHomeLocation stores error on failure', () async {
    final FakeAuthRepository repo = FakeAuthRepository(
      updateHomeLocationImpl: ({
        required double latitude,
        required double longitude,
        String? label,
      }) async {
        throw const AppError(code: 'VALIDATION_ERROR', message: 'bad');
      },
    );

    final ProviderContainer container = ProviderContainer(
      overrides: AuthTestOverrides(authRepository: repo).build(),
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(homeLocationControllerProvider.notifier).saveHomeLocation(
            latitude: 41.6,
            longitude: 21.7,
          ),
      throwsA(isA<AppError>()),
    );
  });
}
