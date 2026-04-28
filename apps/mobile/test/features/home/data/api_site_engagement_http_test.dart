import 'package:chisto_mobile/features/home/data/api_site_engagement_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('siteShareLinkFromJson', () {
    test('parses tokenized share-link payload', () {
      final payload = siteShareLinkFromJson(<String, dynamic>{
        'siteId': 'c1234567890abcdefghijklmn',
        'cid': 'cid_1',
        'url': 'https://chisto.mk/sites/c1234567890abcdefghijklmn?st=t1&cid=cid_1',
        'token': 't1',
        'channel': 'native',
        'expiresAt': '2026-05-01T00:00:00.000Z',
      });
      expect(payload.siteId, 'c1234567890abcdefghijklmn');
      expect(payload.cid, 'cid_1');
      expect(payload.token, 't1');
      expect(payload.channel, 'native');
      expect(payload.url, contains('st=t1'));
    });
  });
}
