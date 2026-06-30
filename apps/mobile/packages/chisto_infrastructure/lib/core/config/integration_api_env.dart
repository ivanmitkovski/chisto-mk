/// Resolves staging/prod API base URL for env-guarded integration tests.
String integrationApiBaseUrl() {
  const String apiUrlOverride = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );
  if (apiUrlOverride.isNotEmpty) {
    return apiUrlOverride.replaceFirst(RegExp(r'/$'), '');
  }
  const String env = String.fromEnvironment('ENV', defaultValue: '');
  switch (env) {
    case 'staging':
      // TEMP: staging is not deployed yet; integration runs hit the dev backend.
      return 'http://api-dev.chisto.mk';
    case 'prod':
      return 'https://api.chisto.mk';
    default:
      return '';
  }
}
