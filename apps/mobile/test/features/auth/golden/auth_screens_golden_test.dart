import 'dart:typed_data';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_auth/src/application/initial_route_controller.dart';
import 'package:feature_auth/src/application/sign_in_controller.dart';
import 'package:feature_auth/src/application/splash_session_controller.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/constants/splash_constants.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_new_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_otp_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_request_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_success_screen.dart';
import 'package:feature_auth/src/presentation/screens/initial_route_screen.dart';
import 'package:feature_auth/src/presentation/screens/location_screen.dart';
import 'package:feature_auth/src/presentation/screens/onboarding_screen.dart';
import 'package:feature_auth/src/presentation/screens/otp_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_up_screen.dart';
import 'package:feature_auth/src/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/pump_auth_app.dart';
import '../../../shared/widget_test_bootstrap.dart';
import '../support/auth_test_helpers.dart';

/// 1×1 PNG for stable map tiles in goldens.
final Uint8List _k1x1Png = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _FlatTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_k1x1Png);
  }
}

class _SignInWithErrorController extends SignInController {
  @override
  SignInState build() => const SignInState(
    error: AppError(code: 'INVALID_CREDENTIALS', message: 'bad'),
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
    SplashSessionController.pauseAfterRestore = true;
    InitialRouteController.pauseNavigation = true;
    SplashScreen.disableTimersForTests = true;
  });

  tearDownAll(() {
    SplashSessionController.pauseAfterRestore = false;
    InitialRouteController.pauseNavigation = false;
    SplashScreen.disableTimersForTests = false;
  });

  final List<Locale> locales = <Locale>[
    const Locale('en'),
    const Locale('mk'),
    const Locale('sq'),
  ];

  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'sign_in': () => const SignInScreen(),
    'sign_up': () => const SignUpScreen(),
    'otp': () => const OtpScreen(phoneNumber: '+38970123456'),
    'forgot_request': () => const ForgotPasswordRequestScreen(),
    'forgot_otp': () => const ForgotPasswordOtpScreen(
      target: PasswordResetTarget(
        channel: PasswordResetChannel.sms,
        value: '+38970123456',
      ),
    ),
    'forgot_new': () => const ForgotPasswordNewScreen(
      target: PasswordResetTarget(
        channel: PasswordResetChannel.sms,
        value: '+38970123456',
      ),
      code: '123456',
    ),
    'forgot_success': () => const ForgotPasswordSuccessScreen(),
    'onboarding': () => const OnboardingScreen(),
    'splash': () => const SplashScreen(),
    'initial_route': () => const InitialRouteScreen(),
    'location': () => LocationScreen(tileProviderOverride: _FlatTileProvider()),
  };

  final List<Override> authOverrides = AuthTestOverrides().build();

  for (final Locale locale in locales) {
    for (final MapEntry<String, Widget Function()> entry in screens.entries) {
      testWidgets('golden ${entry.key} ${locale.languageCode}', (
        WidgetTester tester,
      ) async {
        await authGoldenSurface(tester);
        await tester.pumpWidget(
          pumpAuthScreen(
            home: entry.value(),
            locale: locale,
            overrides: authOverrides,
          ),
        );
        await tester.pump();
        if (entry.key == 'location') {
          await tester.pump(const Duration(milliseconds: 950));
        } else if (entry.key == 'initial_route') {
          await tester.pump(SplashConstants.initialRouteMinDisplayTime);
          await tester.pump(SplashConstants.initialRouteSessionTimeout);
        } else if (entry.key == 'splash' ||
            entry.key == 'otp' ||
            entry.key == 'forgot_otp') {
          await tester.pump(const Duration(milliseconds: 400));
        } else {
          await tester.pumpAndSettle();
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            '__goldens__/${entry.key}_${locale.languageCode}.png',
          ),
        );
      });
    }
  }

  testWidgets('golden sign_in_error_mk', (WidgetTester tester) async {
    await authGoldenSurface(tester);
    await tester.pumpWidget(
      pumpAuthScreen(
        home: const SignInScreen(),
        locale: const Locale('mk'),
        overrides: <Override>[
          ...authOverrides,
          signInControllerProvider.overrideWith(_SignInWithErrorController.new),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('__goldens__/sign_in_error_mk.png'),
    );
  });
}
