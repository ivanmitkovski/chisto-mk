import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
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
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        '$date, $time',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _HighlightedBody(body: body, query: query),
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
  const _HighlightedBody({required this.body, required this.query});

  final String body;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      );
    }
    final String lowerBody = body.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = <TextSpan>[];
    int start = 0;

    while (start < body.length) {
      final int idx = lowerBody.indexOf(lowerQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: body.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: body.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: body.substring(idx, idx + query.length),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ));
      start = idx + query.length;
    }

    final TextStyle? base = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        );

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: base, children: spans),
    );
  }
}
