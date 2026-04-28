import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class SiteQuickActions extends StatelessWidget {
  const SiteQuickActions({
    super.key,
    required this.onSaveTap,
    required this.onReportTap,
    required this.onShareTap,
    this.isSaved = false,
    this.isReported = false,
  });

  final VoidCallback onSaveTap;
  final VoidCallback onReportTap;
  final VoidCallback onShareTap;
  final bool isSaved;
  final bool isReported;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickActionTile(
            icon: isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
            label: isSaved ? l10n.siteQuickActionSavedLabel : l10n.siteQuickActionSaveSiteLabel,
            semanticsLabel:
                isSaved ? l10n.siteQuickActionSavedLabel : l10n.siteQuickActionSaveSiteLabel,
            onTap: () {
              AppHaptics.tap();
              onSaveTap();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionTile(
            icon: CupertinoIcons.flag,
            label: isReported
                ? l10n.siteQuickActionReportedLabel
                : l10n.siteQuickActionReportIssueLabel,
            semanticsLabel: isReported
                ? l10n.siteQuickActionReportedLabel
                : l10n.siteQuickActionReportIssueLabel,
            onTap: isReported
                ? () {}
                : () {
                    AppHaptics.tap();
                    onReportTap();
                  },
            isDisabled: isReported,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionTile(
            icon: CupertinoIcons.share,
            label: l10n.siteQuickActionShareLabel,
            semanticsLabel: l10n.siteQuickActionShareLabel,
            onTap: () {
              AppHaptics.tap();
              onShareTap();
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    this.isDisabled = false,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: AppSpacing.sm,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 22, color: AppColors.textPrimary),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    label,
                    style: AppTypography.cardSubtitle.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
