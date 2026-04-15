import 'dart:ui' show Locale;

import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Resolves the app [Locale] the same way as [MaterialApp.localeListResolutionCallback]
/// in [main.dart]: explicit [override] wins; else first platform locale matching
/// [AppLocalizations.supportedLocales]; else English.
Locale resolveAppLocale({
  required Locale? override,
  required List<Locale> platformLocales,
}) {
  if (override != null) {
    return override;
  }
  for (final Locale device in platformLocales) {
    for (final Locale s in AppLocalizations.supportedLocales) {
      if (s.languageCode == device.languageCode) {
        return s;
      }
    }
  }
  return const Locale('en');
}

/// BCP-47 style value for [Accept-Language], aligned with API `otpSmsLocaleFromHint`.
String acceptLanguageFromLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'mk':
      return 'mk-MK';
    case 'sq':
      return 'sq-AL';
    case 'en':
    default:
      return 'en';
  }
}
