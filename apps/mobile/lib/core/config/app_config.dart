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

  static AppConfig fromEnvironment() {
    const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod':
        return prod;
      case 'staging':
        return staging;
      default:
        return dev;
    }
  }

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProd => environment == AppEnvironment.prod;
}

enum AppEnvironment { dev, staging, prod }
