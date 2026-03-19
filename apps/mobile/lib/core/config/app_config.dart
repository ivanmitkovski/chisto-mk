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

  /// AWS dev API. Pass URL via --dart-define=API_URL=https://your-alb-url.eu-central-1.elb.amazonaws.com
  static AppConfig get awsDev {
    const String url =
        String.fromEnvironment('API_URL', defaultValue: 'https://api-dev.chisto.mk');
    return AppConfig._(
      apiBaseUrl: url,
      helpCenterUrl: 'https://chisto.mk/help',
      environment: AppEnvironment.dev,
    );
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
