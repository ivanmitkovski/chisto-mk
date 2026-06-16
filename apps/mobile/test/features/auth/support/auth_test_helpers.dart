import 'package:chisto_infrastructure/core/assets/app_assets.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:feature_auth/src/presentation/constants/splash_constants.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_input.dart';
import 'package:feature_onboarding/src/domain/feature_guide_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_repository.dart';
import 'fake_feature_guide_repository.dart';

/// Standard auth test surface (iPhone-class).
/// Wide enough for six OTP digit boxes (72px each) plus horizontal padding.
const Size kAuthTestSurfaceSize = Size(480, 900);

const MediaQueryData kAuthTestMediaQuery = MediaQueryData(
  size: kAuthTestSurfaceSize,
  devicePixelRatio: 1,
  textScaler: TextScaler.linear(1),
  disableAnimations: true,
);

bool _authGoldenAssetsPrecached = false;

Future<void> authGoldenSurface(WidgetTester tester) async {
  await ensureAuthGoldenAssetsPrecached(tester);
  await tester.binding.setSurfaceSize(kAuthTestSurfaceSize);
  final double previousDevicePixelRatio = tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.devicePixelRatio = previousDevicePixelRatio;
    tester.binding.setSurfaceSize(null);
  });
}

Future<void> settleAuthGoldenAssets(
  WidgetTester tester, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await tester.runAsync(() => Future<void>.delayed(delay));
  await tester.pump();
  await tester.pump();
}

/// Loads raster assets used by auth goldens so snapshots are stable on Linux CI.
Future<void> precacheAuthGoldenAssets(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          precacheImage(const AssetImage(AppAssets.peopleCleaning), context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 146,
          height: 146,
          child: SvgPicture.asset(AppAssets.otpIllustration),
        ),
      ),
    ),
  );
  await settleAuthGoldenAssets(
    tester,
    delay: const Duration(milliseconds: 300),
  );
}

Future<void> ensureAuthGoldenAssetsPrecached(WidgetTester tester) async {
  if (_authGoldenAssetsPrecached) {
    return;
  }
  await precacheAuthGoldenAssets(tester);
  _authGoldenAssetsPrecached = true;
}

Future<void> hideOtpKeyboardForGolden(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pump();
}

/// Pumps auth goldens until animations, timers, and raster assets are stable.
Future<void> settleAuthGolden(WidgetTester tester, String screenKey) async {
  if (screenKey == 'location') {
    await tester.pump(const Duration(milliseconds: 950));
  } else if (screenKey == 'initial_route') {
    await tester.pump(SplashConstants.initialRouteMinDisplayTime);
    await tester.pump(SplashConstants.initialRouteSessionTimeout);
  } else if (screenKey == 'splash' ||
      screenKey == 'otp' ||
      screenKey == 'forgot_otp') {
    await tester.pump(const Duration(milliseconds: 400));
    await hideOtpKeyboardForGolden(tester);
  } else if (screenKey == 'onboarding') {
    await tester.pump(const Duration(milliseconds: 400));
    await settleAuthGoldenAssets(
      tester,
      delay: const Duration(milliseconds: 300),
    );
  } else {
    await tester.pumpAndSettle();
  }
  if (screenKey != 'onboarding') {
    await settleAuthGoldenAssets(tester);
  }
}

/// Provider overrides for isolated auth screen tests.
class AuthTestOverrides {
  AuthTestOverrides({
    AuthRepository? authRepository,
    FeatureGuideRepository? featureGuideRepository,
    Map<String, Object>? preferenceValues,
    this.localeOverride,
  }) : authRepository = authRepository ?? FakeAuthRepository(),
       featureGuideRepository =
           featureGuideRepository ?? FakeFeatureGuideRepository(),
       preferenceValues = preferenceValues ?? <String, Object>{};

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
  final List<Override> allOverrides = <Override>[...?overrides];
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
      home: MediaQuery(data: kAuthTestMediaQuery, child: home),
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

/// Enters OTP via the overlay field in [AuthOtpInput].
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
