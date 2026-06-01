import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/take_action_type.dart';
import 'package:flutter/material.dart';

class TakeActionSheet extends StatelessWidget {
  const TakeActionSheet({super.key, this.canCreateEcoAction = true});

  final bool canCreateEcoAction;

  static Future<TakeActionType?> show(
    BuildContext context, {
    bool canCreateEcoAction = true,
  }) {
    return showAppPanelBottomSheet<TakeActionType>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) =>
          TakeActionSheet(canCreateEcoAction: canCreateEcoAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: context.l10n.takeActionSheetTitle,
      subtitle: context.l10n.takeActionSheetSubtitle,
      useModalRouteShape: true,
      trailing: AppCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: context.l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (canCreateEcoAction)
              _TakeActionTile(
                icon: Icons.add_circle_outline_rounded,
                title: context.l10n.takeActionCreateEcoTitle,
                subtitle: context.l10n.takeActionCreateEcoSubtitle,
                onTap: () => _popWith(context, TakeActionType.createEcoAction),
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
    );
  }
}

void _popWith(BuildContext context, TakeActionType type) {
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
      child: AppActionTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        variant: AppActionTileVariant.compact,
      ),
    );
  }
}
