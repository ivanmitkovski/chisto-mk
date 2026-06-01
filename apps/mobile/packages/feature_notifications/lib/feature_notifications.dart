/// Push notifications, inbox UI, and notification routing.
library;

export 'src/application/notifications_providers.dart';
export 'src/data/event_chat_foreground_scope.dart';
export 'src/data/event_chat_mark_read_result.dart';
export 'src/data/event_chat_notification_sync.dart';
export 'src/data/firebase_background_message_handler.dart';
export 'src/data/notification_inbox_actions.dart';
export 'src/data/notification_inbox_refresh.dart';
export 'src/data/notifications_inbox_coordinator.dart';
export 'src/data/notifications_realtime_service.dart';
export 'src/data/push_notification_service.dart';
export 'src/domain/inbox_groups.dart';
export 'src/domain/models/notification_inbox_highlight.dart';
export 'src/domain/models/user_notification.dart';
export 'src/domain/notifications_grouping.dart';
export 'src/domain/notifications_time_format.dart';
export 'src/domain/repositories/notifications_repository.dart';
export 'src/presentation/notifications_inbox/notifications_inbox_screen.dart';
export 'src/presentation/push_permission_ui.dart';
export 'src/presentation/widgets/notification_actor_avatar_stack.dart';

const String featureNotificationsPackageVersion = '0.0.1';
