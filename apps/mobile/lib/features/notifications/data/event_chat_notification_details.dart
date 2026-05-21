import 'package:chisto_mobile/features/notifications/data/event_chat_push_actions.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_payload.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shared local-notification presentation for EVENT_CHAT (foreground + background).
class EventChatNotificationDetails {
  const EventChatNotificationDetails({
    required this.androidChannel,
    required this.replyActionTitle,
    required this.replyInputLabel,
  });

  final AndroidChannelInfo androidChannel;
  final String replyActionTitle;
  final String replyInputLabel;

  NotificationDetails forData(Map<String, dynamic> data) {
    final String? type = data['type'] as String?;
    final bool isEventChat = type == 'EVENT_CHAT';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannel.id,
        androidChannel.name,
        channelDescription: androidChannel.description,
        importance: androidChannel.importance,
        priority: Priority.high,
        category: isEventChat ? AndroidNotificationCategory.message : null,
        groupKey: isEventChat
            ? PushNotificationPayload.eventChatOsGroupId(data)
            : null,
        tag: isEventChat
            ? PushNotificationPayload.eventChatNotificationTag(data)
            : null,
        actions: isEventChat
            ? <AndroidNotificationAction>[
                AndroidNotificationAction(
                  EventChatPushActions.replyActionId,
                  replyActionTitle,
                  showsUserInterface: false,
                  inputs: <AndroidNotificationActionInput>[
                    AndroidNotificationActionInput(
                      label: replyInputLabel,
                    ),
                  ],
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: isEventChat
            ? PushNotificationPayload.eventChatOsGroupId(data)
            : null,
        categoryIdentifier:
            isEventChat ? EventChatPushActions.apnsCategoryId : null,
      ),
    );
  }

  static List<DarwinNotificationCategory> darwinCategories({
    required String replyTitle,
    required String replyButtonTitle,
    required String replyPlaceholder,
  }) {
    return <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        EventChatPushActions.apnsCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.text(
            EventChatPushActions.replyActionId,
            replyTitle,
            buttonTitle: replyButtonTitle,
            placeholder: replyPlaceholder,
          ),
        ],
      ),
    ];
  }
}
