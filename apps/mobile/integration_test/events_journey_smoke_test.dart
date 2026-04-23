import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Staging / preview API smoke: validates authenticated `GET /events`, `GET /auth/me`,
/// optional `GET /events/:id` (check-in / detail), and organizer quiz fetch.
///
/// Run when credentials are available:
/// ```sh
/// cd apps/mobile
/// flutter test integration_test/events_journey_smoke_test.dart \
///   --dart-define=API_URL=https://api-staging.example.com \
///   --dart-define=INTEGRATION_TEST_ACCESS_TOKEN=eyJ... \
///   --dart-define=INTEGRATION_TEST_EVENT_ID=optional-event-uuid
/// ```
///
/// Without `API_URL` **or** `INTEGRATION_TEST_ACCESS_TOKEN`, the test completes
/// immediately (skipped) so CI stays green.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  const String accessToken =
      String.fromEnvironment('INTEGRATION_TEST_ACCESS_TOKEN', defaultValue: '');
  const String eventId = String.fromEnvironment('INTEGRATION_TEST_EVENT_ID', defaultValue: '');

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

  testWidgets('events list accepts optional nearLat/nearLng for site distance', (WidgetTester tester) async {
    if (!configured) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/events?limit=1&nearLat=41.9965&nearLng=21.4280');
    final http.Response res = await http.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    expect(res.statusCode, 200, reason: 'GET $uri');
    final Object? decoded = json.decode(res.body);
    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> body = decoded! as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;
    if (data.isNotEmpty && data.first is Map<String, dynamic>) {
      final Map<String, dynamic> first = data.first as Map<String, dynamic>;
      expect(first.containsKey('siteDistanceKm'), isTrue);
      expect(first['siteDistanceKm'], isA<num>());
    }
  });

  testWidgets('GET /auth/me returns profile with organizer certification field when configured', (
    WidgetTester tester,
  ) async {
    if (!configured) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/auth/me');
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
    expect(body.containsKey('id'), isTrue);
    expect(body['id'], isA<String>());
    expect(body.containsKey('organizerCertifiedAt'), isTrue);
    expect(
      body['organizerCertifiedAt'] == null || body['organizerCertifiedAt'] is String,
      isTrue,
    );
  });

  testWidgets('GET /auth/me/organizer-certification/quiz returns quiz or already-certified', (
    WidgetTester tester,
  ) async {
    if (!configured) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/auth/me/organizer-certification/quiz');
    final http.Response res = await http.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Accept-Language': 'en',
      },
    );
    expect(
      <int>{200, 403}.contains(res.statusCode),
      isTrue,
      reason: 'GET $uri status=${res.statusCode} body=${res.body}',
    );
    if (res.statusCode != 200) {
      return;
    }
    final Object? decoded = json.decode(res.body);
    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> body = decoded! as Map<String, dynamic>;
    expect(body.containsKey('quizSession'), isTrue);
    expect(body['quizSession'], isA<String>());
    expect(body.containsKey('questions'), isTrue);
    expect(body['questions'], isA<List<dynamic>>());
    expect((body['questions'] as List<dynamic>).isNotEmpty, isTrue);
  });

  testWidgets('GET /events/:id returns mobile event envelope when event id configured', (
    WidgetTester tester,
  ) async {
    if (!configured || eventId.isEmpty) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/events/$eventId');
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
    expect(body.containsKey('data'), isTrue);
    final Object? data = body['data'];
    expect(data, isA<Map<String, dynamic>>());
    final Map<String, dynamic> event = data! as Map<String, dynamic>;
    expect(event['id'], eventId);
    expect(event.containsKey('title'), isTrue);
  });

  testWidgets('GET /events/:eventId/check-in/qr returns payload or auth guard when event id configured', (
    WidgetTester tester,
  ) async {
    if (!configured || eventId.isEmpty) {
      return;
    }
    final String base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final Uri uri = Uri.parse('$base/events/$eventId/check-in/qr');
    final http.Response res = await http.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    expect(
      <int>{200, 403, 404}.contains(res.statusCode),
      isTrue,
      reason: 'GET $uri status=${res.statusCode} body=${res.body}',
    );
    if (res.statusCode != 200) {
      return;
    }
    final Object? decoded = json.decode(res.body);
    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> body = decoded! as Map<String, dynamic>;
    expect(body.containsKey('data'), isTrue);
    final Object? data = body['data'];
    expect(data, isA<Map<String, dynamic>>());
    final Map<String, dynamic> payload = data! as Map<String, dynamic>;
    expect(payload.containsKey('qrPayload'), isTrue);
    expect(payload['qrPayload'], isA<String>());
    expect((payload['qrPayload'] as String).isNotEmpty, isTrue);
  });
}
