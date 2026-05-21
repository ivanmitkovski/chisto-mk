library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:image_picker/image_picker.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_client_message_id.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_diagnostics.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_upload_limits.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_outbox_sync.dart';
import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_fetch_result.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_participants.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_read_cursor.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_chat_message_grouping.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_chat_message_list_order.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_chat_search_merge.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_mime.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/event_chat_audio_playback_scope.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_stream_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_connection_banner.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_date_separator.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_empty_state.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_input_bar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_location_picker_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_pinned_bar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_participants_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_pinned_messages_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_swipe_reply_wrapper.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_system_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_typing_indicator_row.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_error_view.dart';
import 'package:chisto_mobile/features/events/presentation/event_chat/widgets/event_chat_scroll_behavior.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_foreground_scope.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_notification_sync.dart';
import 'package:chisto_mobile/features/events/presentation/event_chat/widgets/event_chat_search_panel.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';

part '../event_chat/event_chat_screen_state.dart';
part '../event_chat/controllers/event_chat_title_bootstrap_coordinator.dart';
part '../event_chat/controllers/event_chat_connection_coordinator.dart';
part '../event_chat/controllers/event_chat_messages_load_coordinator.dart';
part '../event_chat/controllers/event_chat_scroll_coordinator.dart';
part '../event_chat/controllers/event_chat_stream_coordinator.dart';
part '../event_chat/controllers/event_chat_outbox_coordinator.dart';
part '../event_chat/controllers/event_chat_send_media_coordinator.dart';
part '../event_chat/controllers/event_chat_send_actions_coordinator.dart';
part '../event_chat/controllers/event_chat_search_coordinator.dart';
part '../event_chat/controllers/event_chat_moderation_coordinator.dart';
part '../event_chat/widgets/event_chat_app_bar.dart';

/// Event chat for a cleanup event. Listens to [EventChatRepository.messageStream] for live updates.
///
/// **Realtime smoke (manual):** send a message and confirm live delivery (not poll-only); close
/// and reopen the screen — messages should load without relying on error retry.
/// Event chat for a cleanup event. Listens to [EventChatRepository.messageStream] for live updates.
///
/// **Realtime smoke (manual):** send a message and confirm live delivery (not poll-only); close
/// and reopen the screen — messages should load without relying on error retry.
class EventChatScreen extends StatefulWidget {
  const EventChatScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.isOrganizer,
    this.repository,
    this.readSyncCompleter,
  });

  final String eventId;
  final String eventTitle;
  final bool isOrganizer;
  final EventChatRepository? repository;

  /// Completed after best-effort read cursor sync on exit (for parent refresh timing).
  final Completer<void>? readSyncCompleter;

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}
