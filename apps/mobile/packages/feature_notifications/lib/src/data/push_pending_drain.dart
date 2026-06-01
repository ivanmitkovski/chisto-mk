import 'package:feature_notifications/src/data/event_chat_push_reply_service.dart';
import 'package:feature_notifications/src/data/notification_inbox_refresh.dart';
import 'package:feature_notifications/src/data/push_background_pending_store.dart';

/// Applies drained background push state to bell + inbox (main isolate only).
Future<PendingPushDrainResult> drainAndApplyPendingPushState() async {
  final PendingPushDrainResult pending =
      await PushBackgroundPendingStore.drainPending();
  if (pending.unreadCount != null) {
    publishNotificationsUnreadCount(pending.unreadCount!);
  }
  if (pending.inboxBump) {
    bumpNotificationsInboxRefreshTick();
  }
  await EventChatPushReplyService.drainPendingReplies();
  return pending;
}
