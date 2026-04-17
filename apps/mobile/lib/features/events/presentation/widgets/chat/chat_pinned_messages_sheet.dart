import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';

Future<void> showChatPinnedMessagesSheet({
  required BuildContext context,
  required List<EventChatMessage> pinned,
  required void Function(EventChatMessage message) onSelect,
  bool isOrganizer = false,
  void Function(EventChatMessage message)? onUnpin,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
    ),
    builder: (BuildContext ctx) {
      final double maxH = math.min(MediaQuery.sizeOf(ctx).height * 0.5, 420);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  context.l10n.eventChatPinnedMessagesTitle,
                  style: AppTypography.eventsCalendarMonthTitle(Theme.of(ctx).textTheme),
                ),
              ),
              if (pinned.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    context.l10n.eventChatNoPinnedMessages,
                    textAlign: TextAlign.center,
                    style: AppTypography.eventsBodyMediumSecondary(Theme.of(ctx).textTheme),
                  ),
                )
              else
                SizedBox(
                  height: maxH,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: pinned.length,
                    separatorBuilder: (BuildContext _, int _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (BuildContext c, int i) {
                      final EventChatMessage m = pinned[i];
                      final Widget bubble = _PinnedMiniBubble(
                        message: m,
                        isOrganizer: isOrganizer,
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelect(m);
                        },
                        onUnpin: isOrganizer && onUnpin != null
                            ? () {
                                Navigator.pop(ctx);
                                onUnpin(m);
                              }
                            : null,
                      );
                      if (!isOrganizer || onUnpin == null) {
                        return bubble;
                      }
                      return Dismissible(
                        key: ValueKey<String>(m.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.accentDanger.withValues(alpha: 0.1),
                            borderRadius: ChatTheme.bubbleRadiusSymmetric,
                          ),
                          child: Icon(CupertinoIcons.pin_slash, color: AppColors.accentDanger),
                        ),
                        confirmDismiss: (_) async => true,
                        onDismissed: (_) {
                          Navigator.pop(ctx);
                          onUnpin(m);
                        },
                        child: bubble,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _PinnedMiniBubble extends StatelessWidget {
  const _PinnedMiniBubble({
    required this.message,
    required this.onTap,
    this.isOrganizer = false,
    this.onUnpin,
  });
  final EventChatMessage message;
  final VoidCallback onTap;
  final bool isOrganizer;
  final VoidCallback? onUnpin;

  @override
  Widget build(BuildContext context) {
    final String body = (message.body ?? '').trim();
    final String text = body.isEmpty
        ? context.l10n.eventChatMessageRemoved
        : body;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: ChatTheme.bubblePeerFill,
          borderRadius: ChatTheme.bubbleRadiusSymmetric,
          border: Border.all(color: ChatTheme.bubblePeerBorder, width: 0.5),
          boxShadow: ChatTheme.bubblePeerShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(CupertinoIcons.pin_fill, size: 12, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  message.authorName,
                  style: AppTypography.eventsChatAuthorName(Theme.of(context).textTheme).copyWith(
                        color: ChatTheme.avatarColor(message.authorId),
                      ),
                ),
                if (message.pinnedByDisplayName != null &&
                    message.pinnedByDisplayName!.isNotEmpty) ...<Widget>[
                  const Spacer(),
                  Text(
                    context.l10n.eventChatPinnedBy(message.pinnedByDisplayName!),
                    style: AppTypography.eventsChatTimestamp(Theme.of(context).textTheme),
                  ),
                ],
                if (isOrganizer && onUnpin != null) ...<Widget>[
                  if (message.pinnedByDisplayName == null ||
                      message.pinnedByDisplayName!.isEmpty)
                    const Spacer(),
                  GestureDetector(
                    onTap: onUnpin,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                      child: Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.eventsSupportingCaption(Theme.of(context).textTheme),
            ),
          ],
        ),
      ),
    );
  }
}
