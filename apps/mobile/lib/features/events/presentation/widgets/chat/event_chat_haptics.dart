import 'package:flutter/widgets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Semantic haptics for event chat (single place to tune intensity per action).
abstract final class EventChatHaptics {
  static void swipeReplyThreshold(BuildContext? context) => AppHaptics.light(context);

  static void liveMessageDelivered() => AppHaptics.light();

  static void attachmentPickerTap(BuildContext? context) => AppHaptics.tap(context);
}
