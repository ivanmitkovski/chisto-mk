import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

enum FeedCardFeedbackAction {
  notRelevant,
  showLess,
  duplicate,
  misleading,
  hide,
}

/// Bottom sheet: feed card overflow menu (not relevant, hide, etc.).
class FeedFeedbackSheet extends StatelessWidget {
  const FeedFeedbackSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.siteCardFeedOptionsSheetTitle,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.siteCardFeedOptionsSheetSubtitle,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FeedFeedbackTile(
                icon: Icons.visibility_off_outlined,
                title: context.l10n.siteCardNotRelevantTitle,
                onTap: () =>
                    Navigator.of(context).pop(FeedCardFeedbackAction.notRelevant),
              ),
              FeedFeedbackTile(
                icon: Icons.auto_awesome_outlined,
                title: context.l10n.siteCardShowLessTitle,
                onTap: () =>
                    Navigator.of(context).pop(FeedCardFeedbackAction.showLess),
              ),
              FeedFeedbackTile(
                icon: Icons.copy_all_outlined,
                title: context.l10n.siteCardDuplicateTitle,
                onTap: () =>
                    Navigator.of(context).pop(FeedCardFeedbackAction.duplicate),
              ),
              FeedFeedbackTile(
                icon: Icons.warning_amber_rounded,
                title: context.l10n.siteCardMisleadingTitle,
                onTap: () =>
                    Navigator.of(context).pop(FeedCardFeedbackAction.misleading),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              FeedFeedbackTile(
                icon: Icons.hide_source_rounded,
                title: context.l10n.siteCardHidePostTitle,
                isDestructive: true,
                onTap: () =>
                    Navigator.of(context).pop(FeedCardFeedbackAction.hide),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedFeedbackTile extends StatelessWidget {
  const FeedFeedbackTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        isDestructive ? AppColors.accentDanger : AppColors.textPrimary;
    final Color textColor =
        isDestructive ? AppColors.accentDanger : AppColors.textPrimary;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: <Widget>[
              Icon(icon, size: AppSpacing.iconLg, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
