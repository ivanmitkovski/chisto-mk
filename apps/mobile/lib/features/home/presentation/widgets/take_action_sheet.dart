import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/share_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class TakeActionSheet extends StatelessWidget {
  const TakeActionSheet({super.key});

  static Future<TakeActionType?> show(BuildContext context) {
    AppHaptics.medium();
    return showModalBottomSheet<TakeActionType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => const TakeActionSheet(),
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
                  'Take action',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how you want to help',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TakeActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Create eco action',
                  subtitle: 'Schedule a cleanup event at this site',
                  onTap: () => _popWith(context, TakeActionType.createEcoAction),
                ),
                _TakeActionTile(
                  icon: Icons.groups_rounded,
                  title: 'Join action',
                  subtitle: 'Find and join upcoming cleanups here',
                  onTap: () => _popWith(context, TakeActionType.joinAction),
                ),
                _TakeActionTile(
                  icon: Icons.volunteer_activism_rounded,
                  title: 'Donate / contribute',
                  subtitle: 'Support cleanup efforts financially',
                  onTap: () => _popWith(context, TakeActionType.donateContribute),
                ),
                _TakeActionTile(
                  icon: Icons.share_rounded,
                  title: 'Share site',
                  subtitle: 'Help others discover this site',
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
