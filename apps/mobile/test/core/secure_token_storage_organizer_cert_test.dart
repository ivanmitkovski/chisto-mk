import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('writeOrganizerCertifiedAt persists ISO; clearTokens removes it', () async {
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.saveTokens(
      accessToken: 'a',
      refreshToken: 'r',
    );
    final DateTime at = DateTime.utc(2026, 4, 1, 8, 30);
    await storage.writeOrganizerCertifiedAt(at);

    final String? iso = await storage.organizerCertifiedAtIso;
    expect(iso, isNotNull);
    expect(DateTime.parse(iso!).toUtc(), at);

    await storage.clearTokens();
    expect(await storage.organizerCertifiedAtIso, isNull);
    expect(await storage.accessToken, isNull);
  });
}
