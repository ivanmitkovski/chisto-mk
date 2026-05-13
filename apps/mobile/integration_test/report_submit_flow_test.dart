import 'dart:convert';

import 'package:chisto_mobile/features/reports/data/api_reports_json_wrappers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Staging smoke for authenticated **reports list** and **minimal POST /reports** (env-guarded).
///
/// Full UI wizard + multipart photo flow still benefits from device/nightly runs — see
/// `docs/reports-outbox-runbook.md`.
///
/// ```sh
/// cd apps/mobile
/// flutter test integration_test/report_submit_flow_test.dart \
///   --dart-define=API_URL=https://api-staging.example.com \
///   --dart-define=INTEGRATION_TEST_ACCESS_TOKEN=eyJ...
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  const String accessToken =
      String.fromEnvironment('INTEGRATION_TEST_ACCESS_TOKEN', defaultValue: '');

  final bool configured = apiUrl.isNotEmpty && accessToken.isNotEmpty;

  testWidgets('GET /reports returns envelope when configured', (WidgetTester tester) async {
    if (!configured) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/reports?limit=1');
    final http.Response res = await http.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    expect(res.statusCode, 200, reason: 'GET $uri body: ${res.body}');
    final Object? decoded = json.decode(res.body);
    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> body = decoded! as Map<String, dynamic>;
    expect(body['data'], isA<List<dynamic>>());
  });

  testWidgets('POST /reports returns 201 for minimal JSON body when configured', (WidgetTester tester) async {
    if (!configured) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/reports');
    final http.Response res = await http.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(<String, Object?>{
        'latitude': 41.9981,
        'longitude': 21.4254,
        'title': 'integration_test smoke ${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
    expect(res.statusCode, 201, reason: 'POST $uri body: ${res.body}');
    final Object? decoded = json.decode(res.body);
    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> body = decoded! as Map<String, dynamic>;
    final Map<String, dynamic> payload = createReportSubmitPayload(body);
    expect(payload['reportId']?.toString(), isNotEmpty);
  });
}
