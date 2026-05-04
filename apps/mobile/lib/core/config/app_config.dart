class AppConfig {
  const AppConfig._({
    required this.apiBaseUrl,
    required this.helpCenterUrl,
    required this.environment,
  });

  final String apiBaseUrl;
  final String helpCenterUrl;
  final AppEnvironment environment;

  static const AppConfig dev = AppConfig._(
    apiBaseUrl: 'https://api-dev.chisto.mk',
    helpCenterUrl: 'https://chisto.mk/help',
    environment: AppEnvironment.dev,
  );

  static const AppConfig staging = AppConfig._(
    apiBaseUrl: 'https://api-staging.chisto.mk',
    helpCenterUrl: 'https://chisto.mk/help',
    environment: AppEnvironment.staging,
  );

  static const AppConfig prod = AppConfig._(
    apiBaseUrl: 'https://api.chisto.mk',
    helpCenterUrl: 'https://chisto.mk/help',
    environment: AppEnvironment.prod,
  );

  /// Local API (iOS Simulator). Use with --dart-define=ENV=local
  static const AppConfig local = AppConfig._(
    apiBaseUrl: 'http://127.0.0.1:3000',
    helpCenterUrl: 'https://chisto.mk/help',
    environment: AppEnvironment.dev,
  );

  /// Local API (Android Emulator). Use with --dart-define=ENV=localAndroid
  static const AppConfig localAndroid = AppConfig._(
    apiBaseUrl: 'http://10.0.2.2:3000',
    helpCenterUrl: 'https://chisto.mk/help',
    environment: AppEnvironment.dev,
  );

  /// Local API on physical device. Pass your computer's IP via API_HOST.
  /// Example: flutter run --dart-define=ENV=localDevice --dart-define=API_HOST=192.168.1.50
  static AppConfig get localDevice {
    const String host = String.fromEnvironment('API_HOST', defaultValue: '192.168.1.100');
    return AppConfig._(
      apiBaseUrl: 'http://$host:3000',
      helpCenterUrl: 'https://chisto.mk/help',
      environment: AppEnvironment.dev,
    );
  }

  /// AWS dev API. Pass URL via `--dart-define=API_URL=...`.
  ///
  /// Use a hostname that matches the **TLS certificate** (e.g. `https://api-dev.chisto.mk`).
  /// A raw `*.elb.amazonaws.com` URL often fails HTTPS/WebSocket handshakes when the cert
  /// is only valid for the custom domain.
  ///
  /// Event chat and **reports owner realtime** (`/socket.io` + `/reports-owner` namespace)
  /// must use the **same** host as REST. ALB rules that only forward `/api` or omit
  /// `/socket.io` break live updates.
  static AppConfig get awsDev {
    const String url =
        String.fromEnvironment('API_URL', defaultValue: 'https://api-dev.chisto.mk');
    return AppConfig._(
      apiBaseUrl: url,
      helpCenterUrl: 'https://chisto.mk/help',
      environment: AppEnvironment.dev,
    );
  }

  /// Base URL for **web** share links (`/events/:id`), without trailing slash.
  ///
  /// Override per environment, e.g.
  /// `--dart-define=SHARE_BASE_URL=https://staging.chisto.mk`
  ///
  /// Defaults to production marketing site when unset.
  static String get shareBaseUrlFromEnvironment {
    const String raw = String.fromEnvironment('SHARE_BASE_URL', defaultValue: '');
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'https://chisto.mk';
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  static AppConfig fromEnvironment() {
    const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod':
        return prod;
      case 'staging':
        return staging;
      case 'local':
        return local;
      case 'localAndroid':
        return localAndroid;
      case 'localDevice':
        return localDevice;
      case 'awsDev':
        return awsDev;
      default:
        return dev;
    }
  }

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProd => environment == AppEnvironment.prod;
}

enum AppEnvironment { dev, staging, prod }
