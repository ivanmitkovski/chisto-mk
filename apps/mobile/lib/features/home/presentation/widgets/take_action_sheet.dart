import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/share_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class TakeActionSheet extends StatelessWidget {
  const TakeActionSheet({
    super.key,
    this.canCreateEcoAction = true,
  });

  final bool canCreateEcoAction;

  static Future<TakeActionType?> show(
    BuildContext context, {
    bool canCreateEcoAction = true,
  }) {
    AppHaptics.medium();
    return showModalBottomSheet<TakeActionType>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => TakeActionSheet(
        canCreateEcoAction: canCreateEcoAction,
      ),
    );
  }

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
          child: SingleChildScrollView(
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.takeActionSheetTitle,
                  style: AppTypography.sheetTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.takeActionSheetSubtitle,
                  style: AppTypography.cardSubtitle.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (canCreateEcoAction)
                  _TakeActionTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: context.l10n.takeActionCreateEcoTitle,
                    subtitle: context.l10n.takeActionCreateEcoSubtitle,
                    onTap: () =>
                        _popWith(context, TakeActionType.createEcoAction),
                  ),
                _TakeActionTile(
                  icon: Icons.groups_rounded,
                  title: context.l10n.takeActionJoinTitle,
                  subtitle: context.l10n.takeActionJoinSubtitle,
                  onTap: () => _popWith(context, TakeActionType.joinAction),
                ),
                _TakeActionTile(
                  icon: Icons.share_rounded,
                  title: context.l10n.takeActionShareTitle,
                  subtitle: context.l10n.takeActionShareSubtitle,
                  onTap: () => _popWith(context, TakeActionType.shareSite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

void _popWith(BuildContext context, TakeActionType type) {
  AppHaptics.tap();
  Navigator.of(context).pop(type);
}

class _TakeActionTile extends StatelessWidget {
  const _TakeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ShareActionTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
