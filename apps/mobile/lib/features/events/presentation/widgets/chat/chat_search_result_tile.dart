import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';

class ChatSearchResultTile extends StatelessWidget {
  const ChatSearchResultTile({
    super.key,
    required this.message,
    required this.query,
    required this.onTap,
  });

  final EventChatMessage message;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String body = (message.body ?? '').trim();
    final String time = DateFormat.jm().format(message.createdAt.toLocal());
    final String date = DateFormat.MMMd().format(message.createdAt.toLocal());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UserAvatarCircle(
              displayName: message.authorName,
              imageUrl: message.authorAvatarUrl,
              size: ChatTheme.avatarSize,
              seed: message.authorId,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          message.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eventsChatAuthorName(textTheme),
                        ),
                      ),
                      Text(
                        '$date, $time',
                        style: AppTypography.eventsChatTimestamp(textTheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _HighlightedBody(body: body, query: query, textTheme: textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedBody extends StatelessWidget {
  const _HighlightedBody({
    required this.body,
    required this.query,
    required this.textTheme,
  });

  final String body;
  final String query;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Text(
        body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.eventsGridPropertyValue(textTheme),
      );
    }
    final String escaped = RegExp.escape(trimmed);
    if (escaped.isEmpty) {
      return Text(
        body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.eventsGridPropertyValue(textTheme),
      );
    }
    final RegExp pattern = RegExp(escaped, caseSensitive: false);
    final List<TextSpan> spans = <TextSpan>[];
    int start = 0;
    for (final Match m in pattern.allMatches(body)) {
      if (m.start > start) {
        spans.add(TextSpan(text: body.substring(start, m.start)));
      }
      spans.add(
        TextSpan(
          text: body.substring(m.start, m.end),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
      start = m.end;
    }
    if (start < body.length) {
      spans.add(TextSpan(text: body.substring(start)));
    }

    final TextStyle base = AppTypography.eventsGridPropertyValue(textTheme);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: base, children: spans),
    );
  }
}
