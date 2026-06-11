import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:chisto_persistence/chisto_persistence.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('persistent mode writes session tokens to secure storage', () async {
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.setPersistenceMode(persistent: true);
    await storage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');

    expect(storage.isPersistent, isTrue);
    expect(await storage.accessToken, 'access-1');
    expect(await storage.refreshToken, 'refresh-1');

    final SecureTokenStorage restarted = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    expect(await restarted.accessToken, 'access-1');
    expect(await restarted.refreshToken, 'refresh-1');
  });

  test('ephemeral mode keeps tokens in memory and clears on-disk session keys', () async {
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.setPersistenceMode(persistent: true);
    await storage.saveTokens(accessToken: 'old-access', refreshToken: 'old-refresh');

    await storage.setPersistenceMode(persistent: false);
    await storage.saveTokens(accessToken: 'mem-access', refreshToken: 'mem-refresh');
    await storage.saveSessionData(
      userId: 'user-1',
      displayName: 'A B',
      phoneNumber: '+38970123456',
    );

    expect(storage.persistenceMode, TokenPersistenceMode.ephemeral);
    expect(await storage.accessToken, 'mem-access');
    expect(await storage.refreshToken, 'mem-refresh');

    final SecureTokenStorage coldStart = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    expect(await coldStart.accessToken, isNull);
    expect(await coldStart.refreshToken, isNull);
    expect(await coldStart.userId, isNull);
  });

  test('deviceId stays persistent in ephemeral mode', () async {
    final SecureTokenStorage storage = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    await storage.setPersistenceMode(persistent: false);
    final String deviceId = await storage.deviceId;

    final SecureTokenStorage restarted = SecureTokenStorage(
      storage: const FlutterSecureStorage(),
    );
    expect(await restarted.deviceId, deviceId);
  });
}
