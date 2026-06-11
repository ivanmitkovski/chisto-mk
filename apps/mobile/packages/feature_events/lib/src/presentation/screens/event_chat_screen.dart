library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/connectivity_gate.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/chat/chat_client_message_id.dart';
import 'package:feature_events/src/data/chat/chat_diagnostics.dart';
import 'package:feature_events/src/data/chat/chat_outbox_sync.dart';
import 'package:feature_events/src/data/chat/chat_upload_limits.dart';
import 'package:feature_events/src/data/chat/event_chat_connection_status.dart';
import 'package:feature_events/src/data/chat/event_chat_fetch_result.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/data/chat/event_chat_participants.dart';
import 'package:feature_events/src/data/chat/event_chat_read_cursor.dart';
import 'package:feature_events/src/data/chat/event_chat_repository.dart';
import 'package:feature_events/src/data/chat/event_chat_stream_event.dart';
import 'package:feature_events/src/data/chat/outbox/chat_outbox_store.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/event_chat/event_chat_load_error.dart';
import 'package:feature_events/src/presentation/event_chat/widgets/event_chat_scroll_behavior.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_not_found_view.dart';
import 'package:feature_events/src/presentation/event_chat/widgets/event_chat_search_panel.dart';
import 'package:feature_events/src/presentation/utils/event_chat_message_grouping.dart';
import 'package:feature_events/src/presentation/utils/event_chat_message_list_order.dart';
import 'package:feature_events/src/presentation/utils/event_chat_search_merge.dart';
import 'package:feature_events/src/presentation/utils/events_diagnostic_log.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_attachment_mime.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_connection_banner.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_date_separator.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_empty_state.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_input_bar.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_location_picker_sheet.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_message_skeleton.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_participants_sheet.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_pinned_bar.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_pinned_messages_sheet.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_swipe_reply_wrapper.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_system_message.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_theme.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_typing_indicator_row.dart';
import 'package:feature_events/src/presentation/widgets/chat/event_chat_audio_playback_scope.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

part '../event_chat/controllers/event_chat_connection_coordinator.dart';
part '../event_chat/controllers/event_chat_messages_load_coordinator.dart';
part '../event_chat/controllers/event_chat_moderation_coordinator.dart';
part '../event_chat/controllers/event_chat_outbox_coordinator.dart';
part '../event_chat/controllers/event_chat_scroll_coordinator.dart';
part '../event_chat/controllers/event_chat_search_coordinator.dart';
part '../event_chat/controllers/event_chat_send_actions_coordinator.dart';
part '../event_chat/controllers/event_chat_send_media_coordinator.dart';
part '../event_chat/controllers/event_chat_stream_coordinator.dart';
part '../event_chat/controllers/event_chat_title_bootstrap_coordinator.dart';
part '../event_chat/event_chat_screen_state.dart';
part '../event_chat/widgets/event_chat_app_bar.dart';

/// Event chat for a cleanup event. Listens to [EventChatRepository.messageStream] for live updates.
///
/// **Realtime smoke (manual):** send a message and confirm live delivery (not poll-only); close
/// and reopen the screen — messages should load without relying on error retry.
/// Event chat for a cleanup event. Listens to [EventChatRepository.messageStream] for live updates.
///
/// **Realtime smoke (manual):** send a message and confirm live delivery (not poll-only); close
/// and reopen the screen — messages should load without relying on error retry.
class EventChatScreen extends ConsumerStatefulWidget {
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
  ConsumerState<EventChatScreen> createState() => _EventChatScreenState();
}
