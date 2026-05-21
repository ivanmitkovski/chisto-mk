import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/profile/profile_avatar_sync.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/auth/data/api_auth_repository.dart';
import 'package:chisto_mobile/features/auth/data/eula_acceptance_store.dart';
import 'package:chisto_mobile/features/auth/data/user_home_location_store.dart';
import 'package:chisto_mobile/features/events/data/check_in_local_cache.dart';
import 'package:chisto_mobile/features/events/data/discovery_analytics.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/home/data/map_search_recents_store.dart';
import 'package:chisto_mobile/features/notifications/data/pending_chat_reply_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiAuthRepository logout cleanup', () {
    late SharedPreferences prefs;
    late ApiAuthRepository repo;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      SharedPreferences.setMockInitialValues(<String, Object>{
        kUserHomeLatitudeKey: 41.99,
        kUserHomeLongitudeKey: 21.43,
        kUserHomeLocationLabelKey: 'Skopje',
        'map_search_recent_v1': '["trash"]',
        'events_checkin_sessions_v1': '[]',
        'events_feedback_snapshot_v1': '{}',
        'pending_chat_replies_v1': '[]',
        'discovery_analytics_consent_v1': true,
      });
      prefs = await SharedPreferences.getInstance();
      final AuthState authState = AuthState();
      authState.setAuthenticated(
        userId: 'u1',
        displayName: 'Test',
        accessToken: 'tok',
      );
      repo = ApiAuthRepository(
        client: ApiClient(
          config: AppConfig.dev,
          accessToken: () => authState.accessToken,
          onUnauthorized: () {},
        ),
        authState: authState,
        tokenStorage: SecureTokenStorage(
          storage: const FlutterSecureStorage(),
        ),
        preferences: prefs,
        avatarSync: const NoOpProfileAvatarSync(),
      );
    });

    test('invalidateLocalSession clears PII SharedPreferences', () async {
      await EulaAcceptanceStore(prefs).acceptForUser('u1');
      await repo.invalidateLocalSession();

      expect(prefs.getDouble(kUserHomeLatitudeKey), isNull);
      expect(await EulaAcceptanceStore(prefs).hasAcceptedForUser('u1'), isTrue);
      expect(MapSearchRecentsStore.readSync(prefs), isEmpty);
      expect(await const CheckInLocalCache().readSessions(), isEmpty);
      expect(await DiscoveryAnalytics.readUserConsent(), isFalse);
      expect(await PendingChatReplyStore.peekAll(), isEmpty);
      expect(
        await const EventFeedbackLocalCache().read('any'),
        isNull,
      );
    });
  });
}
