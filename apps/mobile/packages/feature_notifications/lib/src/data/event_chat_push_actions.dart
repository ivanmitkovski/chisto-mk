/// Must match APNS category from API [`resolveApnsCategory`] for EVENT_CHAT.
abstract final class EventChatPushActions {
  static const String apnsCategoryId = 'EVENT_CHAT_MESSAGE';
  static const String replyActionId = 'EVENT_CHAT_REPLY';
}
