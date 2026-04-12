import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Optional smoke: `GET /events/:eventId/chat/unread-count` with a bearer token.
///
/// ```sh
/// flutter test integration_test/event_chat_smoke_test.dart \
///   --dart-define=API_URL=https://api-staging.example.com \
///   --dart-define=INTEGRATION_TEST_ACCESS_TOKEN=eyJ... \
///   --dart-define=INTEGRATION_TEST_EVENT_ID=cuid...
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  const String accessToken =
      String.fromEnvironment('INTEGRATION_TEST_ACCESS_TOKEN', defaultValue: '');
  const String eventId = String.fromEnvironment('INTEGRATION_TEST_EVENT_ID', defaultValue: '');

  final bool configured =
      apiUrl.isNotEmpty && accessToken.isNotEmpty && eventId.isNotEmpty;

  testWidgets('event chat unread-count API when configured', (WidgetTester tester) async {
    if (!configured) {
      expect(!configured, isTrue);
      return;
    }

    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/events/$eventId/chat/unread-count');
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
    expect(body['data'], isA<Map<String, dynamic>>());
    final Map<String, dynamic> data = body['data']! as Map<String, dynamic>;
    expect(data.containsKey('count'), isTrue);
  });
}
