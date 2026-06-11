import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:chisto_infrastructure/core/l10n/app_locale_resolution.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for the in-app language override (see [AppBootstrap]).
const String kAppLocaleCodeKey = 'app_locale_code';

/// Loads [AppLocalizations] from the persisted in-app locale in a background isolate.
Future<AppLocalizations> loadStoredAppLocalizations() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? code = prefs.getString(kAppLocaleCodeKey);
  final Locale locale;
  if (code == 'en' || code == 'mk' || code == 'sq') {
    locale = Locale(code!);
  } else {
    locale = resolveAppLocale(
      override: null,
      platformLocales: PlatformDispatcher.instance.locales,
    );
  }
  return lookupAppLocalizations(locale);
}
