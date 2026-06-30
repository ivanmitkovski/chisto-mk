import 'package:chisto_networking/chisto_networking.dart';

class AppConfig implements ApiClientConfig {
  const AppConfig._({
    required this.apiBaseUrl,
    required this.helpCenterUrl,
    required this.termsUrl,
    required this.privacyUrl,
    required this.environment,
  });

  @override
  final String apiBaseUrl;
  final String helpCenterUrl;
  final String termsUrl;
  final String privacyUrl;
  final AppEnvironment environment;

  static String _legalUrlFromEnvironment(String key, String fallback) {
    final String raw = String.fromEnvironment(key, defaultValue: '');
    final String trimmed = raw.trim();
    return trimmed.isNotEmpty ? trimmed : fallback;
  }

  /// Marketing help centre base (locale prefix added in [helpCenterUrlForLocale]).
  static const String helpCenterSiteBase = 'https://chisto.mk';

  /// Locale-aware help hub URL (`/mk/help`, `/en/help`, `/sq/help`).
  static String helpCenterUrlForLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
      case 'sq':
      case 'mk':
        return '$helpCenterSiteBase/$languageCode/help';
      default:
        return '$helpCenterSiteBase/mk/help';
    }
  }

  /// Deep link to a specific help article in the user's locale.
  static String helpArticleUrlForLocale(String languageCode, String slug) {
    return '${helpCenterUrlForLocale(languageCode)}/$slug';
  }

  /// TEMP: the dev backend currently has no valid TLS certificate
  /// (`https://api-dev.chisto.mk` fails the handshake), so the app talks to it
  /// over HTTP. Cleartext for this single host is allowlisted in the Android
  /// network security config and iOS ATS exceptions. Switch back to HTTPS once
  /// the dev/staging certificate is provisioned.
  static const String devApiBaseUrl = 'http://api-dev.chisto.mk';

  static final AppConfig dev = AppConfig._(
    apiBaseUrl: devApiBaseUrl,
    helpCenterUrl: 'https://chisto.mk/mk/help',
    termsUrl: _legalUrlFromEnvironment('TERMS_URL', 'https://chisto.mk/terms'),
    privacyUrl: _legalUrlFromEnvironment(
      'PRIVACY_URL',
      'https://chisto.mk/privacy',
    ),
    environment: AppEnvironment.dev,
  );

  /// TEMP: until a real staging/prod environment exists, beta builds
  /// (`build-beta.sh`, ENV=staging) point at the dev backend so internal
  /// testers hit a live API. Repoint to `https://api-staging.chisto.mk` (or
  /// switch beta to ENV=prod) once that environment is deployed.
  static final AppConfig staging = AppConfig._(
    apiBaseUrl: devApiBaseUrl,
    helpCenterUrl: 'https://chisto.mk/mk/help',
    termsUrl: _legalUrlFromEnvironment('TERMS_URL', 'https://chisto.mk/terms'),
    privacyUrl: _legalUrlFromEnvironment(
      'PRIVACY_URL',
      'https://chisto.mk/privacy',
    ),
    environment: AppEnvironment.staging,
  );

  static final AppConfig prod = AppConfig._(
    apiBaseUrl: 'https://api.chisto.mk',
    helpCenterUrl: 'https://chisto.mk/mk/help',
    termsUrl: _legalUrlFromEnvironment('TERMS_URL', 'https://chisto.mk/terms'),
    privacyUrl: _legalUrlFromEnvironment(
      'PRIVACY_URL',
      'https://chisto.mk/privacy',
    ),
    environment: AppEnvironment.prod,
  );

  /// Local API (iOS Simulator). Use with --dart-define=ENV=local
  static final AppConfig local = AppConfig._(
    apiBaseUrl: 'http://127.0.0.1:3000',
    helpCenterUrl: 'https://chisto.mk/mk/help',
    termsUrl: _legalUrlFromEnvironment('TERMS_URL', 'https://chisto.mk/terms'),
    privacyUrl: _legalUrlFromEnvironment(
      'PRIVACY_URL',
      'https://chisto.mk/privacy',
    ),
    environment: AppEnvironment.dev,
  );

  /// Local API (Android Emulator). Use with --dart-define=ENV=localAndroid
  static final AppConfig localAndroid = AppConfig._(
    apiBaseUrl: 'http://10.0.2.2:3000',
    helpCenterUrl: 'https://chisto.mk/mk/help',
    termsUrl: _legalUrlFromEnvironment('TERMS_URL', 'https://chisto.mk/terms'),
    privacyUrl: _legalUrlFromEnvironment(
      'PRIVACY_URL',
      'https://chisto.mk/privacy',
    ),
    environment: AppEnvironment.dev,
  );

  /// Local API on physical device. Pass your computer's IP via API_HOST.
  /// Example: flutter run --dart-define=ENV=localDevice --dart-define=API_HOST=192.168.1.50
  static final AppConfig localDevice = AppConfig._(
    apiBaseUrl:
        'http://${const String.fromEnvironment('API_HOST', defaultValue: '192.168.1.100')}:3000',
    helpCenterUrl: 'https://chisto.mk/mk/help',
    termsUrl: _legalUrlFromEnvironment('TERMS_URL', 'https://chisto.mk/terms'),
    privacyUrl: _legalUrlFromEnvironment(
      'PRIVACY_URL',
      'https://chisto.mk/privacy',
    ),
    environment: AppEnvironment.dev,
  );

  /// AWS dev API. Pass URL via `--dart-define=API_URL=...`.
  ///
  /// Use a hostname that matches the **TLS certificate** (e.g. `https://api-dev.chisto.mk`).
  /// A raw `*.elb.amazonaws.com` URL often fails HTTPS/WebSocket handshakes when the cert
  /// is only valid for the custom domain.
  ///
  /// Event chat and **reports owner realtime** (`/socket.io` + `/reports-owner` namespace)
  /// must use the **same** host as REST. ALB rules that only forward `/api` or omit
  /// `/socket.io` break live updates.
  static final AppConfig awsDev = AppConfig._(
    apiBaseUrl: const String.fromEnvironment(
      'API_URL',
      defaultValue: devApiBaseUrl,
    ),
    helpCenterUrl: 'https://chisto.mk/mk/help',
    termsUrl: _legalUrlFromEnvironment('TERMS_URL', 'https://chisto.mk/terms'),
    privacyUrl: _legalUrlFromEnvironment(
      'PRIVACY_URL',
      'https://chisto.mk/privacy',
    ),
    environment: AppEnvironment.dev,
  );

  /// Base URL for **web** share links (`/events/:id`), without trailing slash.
  ///
  /// Override per environment, e.g.
  /// `--dart-define=SHARE_BASE_URL=https://staging.chisto.mk`
  ///
  /// Defaults to production marketing site when unset.
  static String get shareBaseUrlFromEnvironment {
    const String raw = String.fromEnvironment(
      'SHARE_BASE_URL',
      defaultValue: '',
    );
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'https://chisto.mk';
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  static AppConfig fromEnvironment() {
    const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
    final AppConfig config;
    switch (env) {
      case 'prod':
        config = prod;
      case 'staging':
        config = staging;
      case 'local':
        config = local;
      case 'localAndroid':
        config = localAndroid;
      case 'localDevice':
        config = localDevice;
      case 'awsDev':
        config = awsDev;
      default:
        config = dev;
    }
    config.assertTransportSecurityForEnvironment();
    return config;
  }

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProd => environment == AppEnvironment.prod;

  /// May this config ship in a `--release` build? Staging powers beta builds
  /// (TestFlight / Play internal testing) and prod powers store builds. The
  /// dev family (dev/local/localAndroid/localDevice/awsDev) uses cleartext or
  /// ELB hosts and must never ship, so it is rejected at startup.
  bool get isReleaseEligible => isStaging || isProd;

  /// Rejects cleartext API URLs and raw ELB hostnames for release/prod traffic.
  static void assertReleaseTransportSecurity(String apiBaseUrl) {
    final Uri? uri = Uri.tryParse(apiBaseUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('Invalid API URL: $apiBaseUrl');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      throw StateError(
        'Release builds require HTTPS API URLs (got ${uri.scheme}://${uri.host})',
      );
    }
    final String host = uri.host.toLowerCase();
    if (host.contains('.elb.amazonaws.com') ||
        host.endsWith('.elb.amazonaws.com.cn')) {
      throw StateError(
        'Release builds must not use raw ELB hostnames (got $host)',
      );
    }
  }

  /// Validates [apiBaseUrl] when [environment] is production.
  void assertTransportSecurityForEnvironment() {
    if (isProd) {
      assertReleaseTransportSecurity(apiBaseUrl);
    }
  }

  /// Site detail "History" tab. Override with `--dart-define=SITE_HISTORY_TAB_ENABLED=true|false`.
  ///
  /// **v1 store release:** pass `--dart-define=SITE_HISTORY_TAB_ENABLED=true` after API
  /// migration/backfill ([apps/api/docs/beta-readiness.md]).
  bool get siteHistoryTabEnabled {
    const String raw = String.fromEnvironment(
      'SITE_HISTORY_TAB_ENABLED',
      defaultValue: 'true',
    );
    if (raw == '1' || raw.toLowerCase() == 'true') return true;
    if (raw == '0' || raw.toLowerCase() == 'false') return false;
    return true;
  }
}

enum AppEnvironment { dev, staging, prod }
