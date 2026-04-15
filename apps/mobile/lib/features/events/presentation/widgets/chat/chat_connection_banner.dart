import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Status strip under the app bar when the chat stream is recovering.
class ChatConnectionBanner extends StatelessWidget {
  const ChatConnectionBanner({
    super.key,
    required this.reconnecting,
    this.disconnected = false,
    this.showConnectedFlash = false,
  });

  final bool reconnecting;
  final bool disconnected;
  final bool showConnectedFlash;

  @override
  Widget build(BuildContext context) {
    final bool visible = reconnecting || disconnected || showConnectedFlash;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: AppMotion.medium,
        curve: AppMotion.smooth,
        child: visible
            ? _content(context)
            : const SizedBox(height: 0, width: double.infinity),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final Color bg;
    final IconData icon;
    final String text;

    if (disconnected) {
      bg = AppColors.accentDanger.withValues(alpha: 0.10);
      icon = Icons.cloud_off_outlined;
      text = context.l10n.errorUserNetwork;
    } else if (reconnecting) {
      bg = AppColors.accentWarning.withValues(alpha: 0.10);
      icon = Icons.sync;
      text = context.l10n.eventChatReconnecting;
    } else {
      bg = AppColors.primary.withValues(alpha: 0.08);
      icon = Icons.check_circle_outline;
      text = context.l10n.eventChatConnected;
    }

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            if (reconnecting)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textSecondary,
                ),
              )
            else
              Icon(icon, size: AppSpacing.iconSm, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
