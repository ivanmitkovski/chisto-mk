import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/features/auth/presentation/widgets/auth_otp_input.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/onboarding/domain/feature_guide_repository.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_feature_guide_repository.dart';

/// Standard auth test surface (iPhone-class).
/// Wide enough for six OTP digit boxes (72px each) plus horizontal padding.
const Size kAuthTestSurfaceSize = Size(480, 900);

const MediaQueryData kAuthTestMediaQuery = MediaQueryData(
  size: kAuthTestSurfaceSize,
  devicePixelRatio: 1.0,
  textScaler: TextScaler.linear(1.0),
  disableAnimations: true,
);

Future<void> authGoldenSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(kAuthTestSurfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Provider overrides for isolated auth screen tests.
class AuthTestOverrides {
  AuthTestOverrides({
    AuthRepository? authRepository,
    FeatureGuideRepository? featureGuideRepository,
    Map<String, Object>? preferenceValues,
    Locale? localeOverride,
  })  : authRepository = authRepository ?? FakeAuthRepository(),
        featureGuideRepository =
            featureGuideRepository ?? FakeFeatureGuideRepository(),
        preferenceValues = preferenceValues ?? <String, Object>{},
        localeOverride = localeOverride;

  final AuthRepository authRepository;
  final FeatureGuideRepository featureGuideRepository;
  final Map<String, Object> preferenceValues;
  final Locale? localeOverride;

  List<Override> build() {
    SharedPreferences.setMockInitialValues(preferenceValues);
    return <Override>[
      authRepositoryProvider.overrideWithValue(authRepository),
      featureGuideRepositoryProvider.overrideWithValue(featureGuideRepository),
      appLocaleOverrideProvider.overrideWith((Ref ref) => localeOverride),
      if (AppBootstrap.instance.isInitialized)
        appConfigProvider.overrideWithValue(AppBootstrap.instance.config)
      else
        appConfigProvider.overrideWithValue(AppConfig.local),
    ];
  }
}

Widget pumpAuthScreen({
  required Widget home,
  Locale locale = const Locale('en'),
  List<Override>? overrides,
  RouteFactory? onGenerateRoute,
  NavigatorObserver? navigatorObserver,
}) {
  final List<Override> allOverrides = <Override>[
    ...?overrides,
  ];
  return ProviderScope(
    overrides: allOverrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: onGenerateRoute,
      navigatorObservers: navigatorObserver != null
          ? <NavigatorObserver>[navigatorObserver]
          : const <NavigatorObserver>[],
      home: MediaQuery(
        data: kAuthTestMediaQuery,
        child: home,
      ),
    ),
  );
}

Future<void> pumpAuthWidget(
  WidgetTester tester, {
  required Widget home,
  Locale locale = const Locale('en'),
  List<Override>? overrides,
  RouteFactory? onGenerateRoute,
}) async {
  await tester.pumpWidget(
    pumpAuthScreen(
      home: home,
      locale: locale,
      overrides: overrides,
      onGenerateRoute: onGenerateRoute,
    ),
  );
}

/// Enters OTP via the hidden field behind [AuthOtpInput].
Future<void> enterOtpCode(WidgetTester tester, String code) async {
  final Finder field = find.descendant(
    of: find.byType(AuthOtpInput),
    matching: find.byType(TextField),
  );
  expect(field, findsOneWidget);
  await tester.enterText(field, code);
  await tester.pump();
}

Future<void> pumpOtpResendSeconds(WidgetTester tester, int seconds) async {
  await tester.pump(Duration(seconds: seconds));
}
