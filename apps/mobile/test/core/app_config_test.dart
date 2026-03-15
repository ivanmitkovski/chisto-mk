import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('dev has correct apiBaseUrl, helpCenterUrl and environment', () {
      expect(AppConfig.dev.apiBaseUrl, equals('https://api-dev.chisto.mk'));
      expect(AppConfig.dev.helpCenterUrl, equals('https://chisto.mk/help'));
      expect(AppConfig.dev.environment, equals(AppEnvironment.dev));
    });

    test('staging has correct apiBaseUrl and environment', () {
      expect(
        AppConfig.staging.apiBaseUrl,
        equals('https://api-staging.chisto.mk'),
      );
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
  });
}
