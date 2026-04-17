import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';

/// Centered informational line for server system messages (join/leave/updates).
class ChatSystemMessage extends StatelessWidget {
  const ChatSystemMessage({super.key, required this.message});

  final EventChatMessage message;

  String _line(BuildContext context) {
    final Map<String, dynamic>? p = message.systemPayload;
    final String? action = p?['action'] as String?;
    final String name = (p?['displayName'] as String?)?.trim().isNotEmpty == true
        ? p!['displayName']! as String
        : message.authorName;
    switch (action) {
      case 'user_joined':
        return context.l10n.eventChatSystemUserJoined(name);
      case 'user_left':
        return context.l10n.eventChatSystemUserLeft(name);
      case 'event_updated':
        return context.l10n.eventChatSystemEventUpdated;
      default:
        return message.body?.trim().isNotEmpty == true
            ? message.body!
            : context.l10n.eventChatSystemEventUpdated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = _line(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Center(
        child: Semantics(
          label: text,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.eventsChatSystemLine(Theme.of(context).textTheme),
          ),
        ),
      ),
    );
  }
}
