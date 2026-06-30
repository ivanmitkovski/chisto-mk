import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_events/src/data/event_offline_work_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/widget_test_bootstrap.dart' show ensureWidgetTestPlumbing;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBootstrap', () {
    late AppBootstrap locator;

    setUp(() async {
      locator = AppBootstrap.instance;
      await locator.reset();
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('starts as not initialized', () {
      expect(locator.isInitialized, isFalse);
    });

    test('initialize sets isInitialized to true', () async {
      await ensureWidgetTestPlumbing();
      await locator.initialize();
      expect(locator.isInitialized, isTrue);
    });

    test('double initialization is idempotent', () async {
      await ensureWidgetTestPlumbing();
      await locator.initialize();
      final authState = locator.authState;

      await locator.initialize();
      expect(locator.authState, same(authState));
    });

    test('after init, repositories are available', () async {
      await ensureWidgetTestPlumbing();
      await locator.initialize();
      expect(locator.authRepository, isNotNull);
      expect(locator.eventsRepository, isNotNull);
      expect(locator.checkInRepository, isNotNull);
    });

    test(
      'after init, authState starts unauthenticated (no hardcoded user)',
      () async {
        await ensureWidgetTestPlumbing();
        await locator.initialize();
        expect(locator.authState.isAuthenticated, isFalse);
      },
    );

    test('loads app locale from SharedPreferences on initialize', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale_code': 'mk',
      });
      await ensureWidgetTestPlumbing();
      await locator.initialize();
      setRootProviderContainer(locator.providerContainer);
      expect(readAppLocaleOverride(), const Locale('mk'));
    });

    test('setAppLocale persists and updates notifier', () async {
      await ensureWidgetTestPlumbing();
      await locator.initialize();
      setRootProviderContainer(locator.providerContainer);
      await locator.setAppLocale(const Locale('sq'));
      expect(readAppLocaleOverride(), const Locale('sq'));
      expect(locator.preferences.getString('app_locale_code'), 'sq');

      await locator.setAppLocale(null);
      expect(readAppLocaleOverride(), isNull);
      expect(locator.preferences.containsKey('app_locale_code'), isFalse);
    });

    test('reset sets isInitialized to false', () async {
      await ensureWidgetTestPlumbing();
      await locator.initialize();
      setRootProviderContainer(locator.providerContainer);
      await EventOfflineWorkCoordinator.instance.refreshSnapshot();
      expect(locator.isInitialized, isTrue);

      clearRootProviderContainer();
      await locator.reset();
      expect(locator.isInitialized, isFalse);
    });
  });
}
