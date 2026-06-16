import 'package:feature_notifications/src/data/push_background_pending_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushBackgroundPendingStore drain (resume path)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'drains unread, inbox bump, and stashed tap payload from prefs',
      () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt(kPushPendingUnreadCountKey, 3);
        await prefs.setBool(kPushPendingInboxBumpKey, true);
        await prefs.setString(
          kPushPendingTapPayloadKey,
          '{"type":"REPORT_STATUS","reportId":"report_1"}',
        );

        final PendingPushDrainResult result =
            await PushBackgroundPendingStore.drainPending();

        expect(result.unreadCount, 3);
        expect(result.inboxBump, isTrue);
        expect(result.tapPayload, isNotNull);
        expect(result.tapPayload!['reportId'], 'report_1');
        expect(prefs.getString(kPushPendingTapPayloadKey), isNull);
        expect(prefs.getInt(kPushPendingUnreadCountKey), isNull);
      },
    );
  });
}
