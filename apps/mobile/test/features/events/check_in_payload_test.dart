import 'dart:convert';

import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckInQrPayload', () {
    test('encodes and parses v1 payload', () {
      const CheckInQrPayload payload = CheckInQrPayload(
        eventId: 'evt-42',
        sessionId: 'sess-abc',
        nonce: '123',
        issuedAtMs: 1700000000000,
      );

      final String raw = payload.encode();
      final CheckInQrPayload? parsed = CheckInQrPayload.tryParse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.eventId, equals('evt-42'));
      expect(parsed.sessionId, equals('sess-abc'));
      expect(parsed.nonce, equals('123'));
      expect(parsed.issuedAtMs, equals(1700000000000));
    });

    test('rejects malformed payload values', () {
      expect(CheckInQrPayload.tryParse(null), isNull);
      expect(CheckInQrPayload.tryParse(''), isNull);
      expect(CheckInQrPayload.tryParse('chisto:evt:evt-1'), isNull);
      expect(
        CheckInQrPayload.tryParse('chisto:evt:v1:evt:sess:nonce:not_int'),
        isNull,
      );
    });

    test('parses v2 token envelope for UI (signature not verified client-side)', () {
      final Map<String, dynamic> claims = <String, dynamic>{
        'e': 'evt-v2',
        's': 'sess-v2',
        'j': 'jti-v2',
        'iat': 1700000000,
        'exp': 1700000060,
      };
      final String body =
          base64Url.encode(utf8.encode(json.encode(claims)));
      final String raw = 'chisto:evt:v2:$body.sigignored';
      final CheckInQrPayload? parsed = CheckInQrPayload.tryParse(raw);
      expect(parsed, isNotNull);
      expect(parsed!.eventId, equals('evt-v2'));
      expect(parsed.sessionId, equals('sess-v2'));
      expect(parsed.nonce, equals('jti-v2'));
      expect(parsed.issuedAtMs, equals(1700000000000));
      expect(parsed.opaqueEncoded, equals(raw));
      expect(parsed.encode(), equals(raw));
    });

    test('fromOrganizerQrApiJson parses expiresAt and session', () {
      final Map<String, dynamic> claims = <String, dynamic>{
        'e': 'evt-api',
        's': 'sess-in-token',
        'j': 'jti-1',
        'iat': 1700000000,
        'exp': 1700000060,
      };
      final String body =
          base64Url.encode(utf8.encode(json.encode(claims)));
      final String raw = 'chisto:evt:v2:$body.sigignored';
      final DateTime expiresUtc = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final CheckInQrPayload? payload = CheckInQrPayload.fromOrganizerQrApiJson(
        <String, dynamic>{
          'qrPayload': raw,
          'sessionId': 'sess-row',
          'issuedAtMs': 1711963200000,
          'expiresAt': expiresUtc.toIso8601String(),
        },
      );
      expect(payload, isNotNull);
      expect(payload!.eventId, 'evt-api');
      expect(payload.sessionId, 'sess-row');
      expect(payload.nonce, 'jti-1');
      expect(payload.issuedAtMs, 1711963200000);
      expect(payload.opaqueEncoded, raw);
      expect(
        payload.expiresAtMs,
        expiresUtc.toLocal().millisecondsSinceEpoch,
      );
    });

    test('fromOrganizerQrApiJson returns null when expiresAt missing is ok', () {
      final Map<String, dynamic> claims = <String, dynamic>{
        'e': 'evt-x',
        's': 's',
        'j': 'j',
        'iat': 1700000000,
        'exp': 1700000060,
      };
      final String body =
          base64Url.encode(utf8.encode(json.encode(claims)));
      final String raw = 'chisto:evt:v2:$body.x';
      final CheckInQrPayload? payload = CheckInQrPayload.fromOrganizerQrApiJson(
        <String, dynamic>{
          'qrPayload': raw,
          'sessionId': 'sess-row',
          'issuedAtMs': 100,
        },
      );
      expect(payload, isNotNull);
      expect(payload!.expiresAtMs, isNull);
    });
  });
}
