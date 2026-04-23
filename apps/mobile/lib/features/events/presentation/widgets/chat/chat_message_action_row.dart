import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Tappable row for message overflow actions (reply, copy, delete, …).
class ChatMessageActionRow extends StatelessWidget {
  const ChatMessageActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color fg = destructive ? AppColors.accentDanger : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.eventsChatMessageBody(
                    Theme.of(context).textTheme,
                    color: fg,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
