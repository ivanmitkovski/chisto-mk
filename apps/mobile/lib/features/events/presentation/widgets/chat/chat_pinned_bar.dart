import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Shows the latest pinned message; opens full list on tap.
class ChatPinnedBar extends StatelessWidget {
  const ChatPinnedBar({
    super.key,
    required this.latest,
    this.pinnedCount = 0,
    required this.onOpenAll,
    required this.onTapMessage,
    this.isOrganizer = false,
    this.onUnpinLatest,
  });

  final EventChatMessage? latest;
  final int pinnedCount;
  final VoidCallback onOpenAll;
  final void Function(EventChatMessage message) onTapMessage;
  final bool isOrganizer;
  final VoidCallback? onUnpinLatest;

  @override
  Widget build(BuildContext context) {
    if (latest == null) return const SizedBox.shrink();
    final EventChatMessage m = latest!;
    final String preview = (m.body ?? '').trim();
    final String line = preview.isEmpty ? context.l10n.eventChatPinnedBarHint : preview;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: AppColors.panelBackground,
          child: InkWell(
            onTap: () {
              AppHaptics.softTransition();
              onOpenAll();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm - 2),
              child: Row(
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CupertinoIcons.pin_fill, size: 13, color: AppColors.primary),
                      ),
                      if (pinnedCount > 1)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            ),
                            child: Text(
                              '$pinnedCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AppHaptics.light();
                        onTapMessage(m);
                      },
                      child: Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eventsCalloutSubtitle(Theme.of(context).textTheme),
                      ),
                    ),
                  ),
                  if (isOrganizer && onUnpinLatest != null)
                    GestureDetector(
                      onTap: () {
                        AppHaptics.light();
                        onUnpinLatest!();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                        child: Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: AppColors.textMuted),
                      ),
                    ),
                  Icon(CupertinoIcons.chevron_up, size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
        Container(height: 0.5, color: AppColors.divider.withValues(alpha: 0.3)),
      ],
    );
  }
}
