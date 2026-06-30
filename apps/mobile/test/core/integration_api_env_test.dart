import 'package:chisto_infrastructure/core/config/integration_api_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('integrationApiBaseUrl empty without ENV or API_URL', () {
    expect(integrationApiBaseUrl(), '');
  });
}
