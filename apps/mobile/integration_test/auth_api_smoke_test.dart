import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'integration_api_env.dart';

/// Staging smoke for auth password-reset request (env-guarded).
///
/// ```sh
/// cd apps/mobile
/// flutter test integration_test/auth_api_smoke_test.dart \
///   --dart-define=API_URL=https://api-staging.example.com \
///   --dart-define=E2E_TEST_PHONE=+38970123456
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String phone = String.fromEnvironment('E2E_TEST_PHONE', defaultValue: '');

  final String apiUrl = integrationApiBaseUrl();
  final bool configured = apiUrl.isNotEmpty && phone.isNotEmpty;

  testWidgets('POST /auth/password-reset/request when configured', (
    WidgetTester tester,
  ) async {
    if (!configured) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/auth/password-reset/request');
    final http.Response res = await http.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: json.encode(<String, String>{'phoneNumber': phone}),
    );
    expect(res.statusCode, 200, reason: 'POST $uri body: ${res.body}');
    final Object? decoded = json.decode(res.body);
    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> body = decoded! as Map<String, dynamic>;
    expect(body['message'], isA<String>());
  });
}
