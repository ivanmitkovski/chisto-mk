import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Localized Android notification channels (ids must match [PushNotificationPayload]).
List<AndroidNotificationChannel> buildPushAndroidNotificationChannels(
  AppLocalizations strings,
) {
  return <AndroidNotificationChannel>[
    AndroidNotificationChannel(
      'chisto_default',
      strings.pushChannelDefaultName,
      description: strings.pushChannelDefaultDescription,
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'chisto_event_chat',
      strings.eventChatPushChannelName,
      description: strings.eventChatPushChannelDescription,
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'chisto_reports',
      strings.pushChannelReportsName,
      description: strings.pushChannelReportsDescription,
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'chisto_events',
      strings.pushChannelEventsName,
      description: strings.pushChannelEventsDescription,
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'chisto_social',
      strings.pushChannelSocialName,
      description: strings.pushChannelSocialDescription,
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      'chisto_system',
      strings.pushChannelSystemName,
      description: strings.pushChannelSystemDescription,
      importance: Importance.defaultImportance,
    ),
  ];
}
