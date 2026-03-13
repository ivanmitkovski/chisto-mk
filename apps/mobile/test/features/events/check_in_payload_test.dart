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
  });
}
