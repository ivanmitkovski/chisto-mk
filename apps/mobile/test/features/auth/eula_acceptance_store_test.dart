import 'package:chisto_mobile/features/auth/data/eula_acceptance_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String userA = 'user_a';
  const String userB = 'user_b';

  late SharedPreferences prefs;
  late EulaAcceptanceStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    store = EulaAcceptanceStore(prefs);
  });

  tearDown(() async {
    await store.clearAllForTests();
  });

  test('acceptForUser persists per user', () async {
    await store.acceptForUser(userA);
    expect(await store.hasAcceptedForUser(userA), isTrue);
    expect(await store.hasAcceptedForUser(userB), isFalse);
  });

  test('clearForUser removes only that user', () async {
    await store.acceptForUser(userA);
    await store.acceptForUser(userB);
    await store.clearForUser(userA);
    expect(await store.hasAcceptedForUser(userA), isFalse);
    expect(await store.hasAcceptedForUser(userB), isTrue);
  });

  test('empty userId is never accepted', () async {
    expect(await store.hasAcceptedForUser(''), isFalse);
    await store.acceptForUser('');
    expect(await store.hasAcceptedForUser(''), isFalse);
  });

  test('syncFromServer seeds local cache when server does not require acceptance',
      () async {
    await store.syncFromServer(
      userId: userA,
      requiresTermsAcceptance: false,
    );
    expect(await store.hasAcceptedForUser(userA), isTrue);
  });

  test('syncFromServer no-op when server still requires acceptance', () async {
    await store.syncFromServer(
      userId: userA,
      requiresTermsAcceptance: true,
    );
    expect(await store.hasAcceptedForUser(userA), isFalse);
  });

  test('migrateLegacyIfNeeded copies global key to per-user key', () async {
    await prefs.setString(EulaAcceptanceStore.acceptedVersionKey, '1');
    expect(await store.hasAcceptedForUser(userA), isTrue);
    expect(prefs.getString(EulaAcceptanceStore.acceptedVersionKey), isNull);
    expect(
      prefs.getString(EulaAcceptanceStore.keyForUser(userA)),
      EulaAcceptanceStore.currentVersion,
    );
  });
}
