import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Staging / preview API smoke: validates authenticated `GET /events` contract.
///
/// Run when credentials are available:
/// ```sh
/// cd apps/mobile
/// flutter test integration_test/events_journey_smoke_test.dart \
///   --dart-define=API_URL=https://api-staging.example.com \
///   --dart-define=INTEGRATION_TEST_ACCESS_TOKEN=eyJ...
/// ```
///
/// Without `API_URL` **or** `INTEGRATION_TEST_ACCESS_TOKEN`, the test completes
/// immediately (skipped) so CI stays green.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  const String accessToken =
      String.fromEnvironment('INTEGRATION_TEST_ACCESS_TOKEN', defaultValue: '');

  final bool configured = apiUrl.isNotEmpty && accessToken.isNotEmpty;

  testWidgets('events list API returns paginated envelope when configured', (WidgetTester tester) async {
    if (!configured) {
      expect(apiUrl.isEmpty || accessToken.isEmpty, isTrue);
      return;
    }

    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/events?limit=1');
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
    final Object? meta = body['meta'];
    expect(meta, isA<Map<String, dynamic>>());
    final Map<String, dynamic> metaMap = meta! as Map<String, dynamic>;
    expect(metaMap.containsKey('hasMore'), isTrue);
  });
}
