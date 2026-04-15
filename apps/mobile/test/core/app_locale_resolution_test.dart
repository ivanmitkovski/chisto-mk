import 'dart:ui' show Locale;

import 'package:chisto_mobile/core/l10n/app_locale_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAppLocale', () {
    test('uses override when set', () {
      expect(
        resolveAppLocale(
          override: const Locale('mk'),
          platformLocales: const <Locale>[Locale('en', 'US')],
        ),
        const Locale('mk'),
      );
    });

    test('matches first supported platform language', () {
      expect(
        resolveAppLocale(
          override: null,
          platformLocales: const <Locale>[Locale('mk', 'MK'), Locale('en')],
        ),
        const Locale('mk'),
      );
    });

    test('falls back to English when platform unsupported', () {
      expect(
        resolveAppLocale(
          override: null,
          platformLocales: const <Locale>[Locale('de'), Locale('fr')],
        ),
        const Locale('en'),
      );
    });

    test('empty platform list falls back to English', () {
      expect(
        resolveAppLocale(override: null, platformLocales: const <Locale>[]),
        const Locale('en'),
      );
    });
  });

  group('acceptLanguageFromLocale', () {
    test('maps supported codes to API tags', () {
      expect(acceptLanguageFromLocale(const Locale('mk')), 'mk-MK');
      expect(acceptLanguageFromLocale(const Locale('sq')), 'sq-AL');
      expect(acceptLanguageFromLocale(const Locale('en')), 'en');
      expect(acceptLanguageFromLocale(const Locale('en', 'US')), 'en');
    });
  });
}
