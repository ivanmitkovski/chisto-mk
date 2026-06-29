import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('dev points at the temporary HTTP dev backend', () {
      // Dev has no valid TLS cert yet, so the app uses HTTP for it.
      expect(AppConfig.dev.apiBaseUrl, equals('http://api-dev.chisto.mk'));
      expect(AppConfig.dev.helpCenterUrl, equals('https://chisto.mk/mk/help'));
      expect(AppConfig.dev.environment, equals(AppEnvironment.dev));
    });

    test('staging (beta target) points at the dev backend for now', () {
      // TEMP: beta builds hit the dev backend until staging/prod is deployed.
      expect(AppConfig.staging.apiBaseUrl, equals('http://api-dev.chisto.mk'));
      expect(AppConfig.staging.environment, equals(AppEnvironment.staging));
    });

    test('prod has correct apiBaseUrl and environment', () {
      expect(AppConfig.prod.apiBaseUrl, equals('https://api.chisto.mk'));
      expect(AppConfig.prod.environment, equals(AppEnvironment.prod));
    });

    test('isDev, isStaging, isProd return correct booleans', () {
      expect(AppConfig.dev.isDev, isTrue);
      expect(AppConfig.dev.isStaging, isFalse);
      expect(AppConfig.dev.isProd, isFalse);

      expect(AppConfig.staging.isDev, isFalse);
      expect(AppConfig.staging.isStaging, isTrue);
      expect(AppConfig.staging.isProd, isFalse);

      expect(AppConfig.prod.isDev, isFalse);
      expect(AppConfig.prod.isStaging, isFalse);
      expect(AppConfig.prod.isProd, isTrue);
    });

    test('fromEnvironment returns dev by default', () {
      final config = AppConfig.fromEnvironment();
      expect(config, equals(AppConfig.dev));
      expect(config.environment, equals(AppEnvironment.dev));
    });

    test('isReleaseEligible allows staging (beta) and prod, rejects dev', () {
      // Beta builds (build-beta.sh) ship ENV=staging; store builds ship prod.
      expect(AppConfig.staging.isReleaseEligible, isTrue);
      expect(AppConfig.prod.isReleaseEligible, isTrue);

      // Dev-family configs must never start a release build.
      expect(AppConfig.dev.isReleaseEligible, isFalse);
      expect(AppConfig.local.isReleaseEligible, isFalse);
      expect(AppConfig.localAndroid.isReleaseEligible, isFalse);
      expect(AppConfig.localDevice.isReleaseEligible, isFalse);
      expect(AppConfig.awsDev.isReleaseEligible, isFalse);
    });

    test('release transport security is enforced for prod only', () {
      // Prod must be HTTPS; main.dart runs assertReleaseTransportSecurity only
      // when config.isProd, so the temporary cleartext dev/staging URL (which
      // would otherwise be rejected) does not block beta startup.
      expect(
        () =>
            AppConfig.assertReleaseTransportSecurity(AppConfig.prod.apiBaseUrl),
        returnsNormally,
      );
      expect(
        () => AppConfig.assertReleaseTransportSecurity(
          AppConfig.staging.apiBaseUrl,
        ),
        throwsStateError,
        reason:
            'cleartext dev URL is only allowed because the check is '
            'prod-only in kReleaseMode',
      );
    });

    test('assertReleaseTransportSecurity accepts HTTPS custom domain', () {
      expect(
        () => AppConfig.assertReleaseTransportSecurity('https://api.chisto.mk'),
        returnsNormally,
      );
    });

    test('assertReleaseTransportSecurity rejects HTTP', () {
      expect(
        () => AppConfig.assertReleaseTransportSecurity('http://api.chisto.mk'),
        throwsStateError,
      );
    });

    test('assertReleaseTransportSecurity rejects raw ELB hostname', () {
      expect(
        () => AppConfig.assertReleaseTransportSecurity(
          'https://chisto-dev-alb-123.eu-central-1.elb.amazonaws.com',
        ),
        throwsStateError,
      );
    });

    test('prod config passes transport security validation', () {
      expect(
        AppConfig.prod.assertTransportSecurityForEnvironment,
        returnsNormally,
      );
    });

    test('helpCenterUrlForLocale returns locale-prefixed help hub', () {
      expect(AppConfig.helpCenterUrlForLocale('en'), 'https://chisto.mk/en/help');
      expect(AppConfig.helpCenterUrlForLocale('mk'), 'https://chisto.mk/mk/help');
      expect(AppConfig.helpCenterUrlForLocale('sq'), 'https://chisto.mk/sq/help');
      expect(AppConfig.helpCenterUrlForLocale('de'), 'https://chisto.mk/mk/help');
    });

    test('helpArticleUrlForLocale builds article deep link', () {
      expect(
        AppConfig.helpArticleUrlForLocale('en', 'report-a-site'),
        'https://chisto.mk/en/help/report-a-site',
      );
    });
  });
}
