import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum CommentOwnerAction { edit, delete }

enum CommentPeerAction { report, block }

/// Design-system sheet for owned-comment actions (edit / delete).
class CommentOwnerActionsSheet extends StatelessWidget {
  const CommentOwnerActionsSheet({super.key});

  static Future<CommentOwnerAction?> show(BuildContext context) {
    return AppBottomSheet.show<CommentOwnerAction>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) => const CommentOwnerActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSheetScaffold(
      title: l10n.commentsSheetTitle,
      subtitle: l10n.commentsSheetSubtitle,
      useModalRouteShape: true,
      trailing: AppCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppActionTile(
              icon: Icons.edit_outlined,
              title: l10n.commentsEditTitle,
              subtitle: l10n.commentsEditSubtitle,
              onTap: () => Navigator.of(context).pop(CommentOwnerAction.edit),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppActionTile(
              icon: Icons.delete_outline_rounded,
              title: l10n.commentsDeleteTitle,
              subtitle: l10n.commentsDeleteSubtitle,
              tone: AppSurfaceTone.danger,
              onTap: () => Navigator.of(context).pop(CommentOwnerAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

/// Design-system sheet for peer-comment moderation actions (report / block).
class CommentPeerActionsSheet extends StatelessWidget {
  const CommentPeerActionsSheet({super.key});

  static Future<CommentPeerAction?> show(BuildContext context) {
    return AppBottomSheet.show<CommentPeerAction>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) => const CommentPeerActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSheetScaffold(
      title: l10n.commentsSheetTitle,
      subtitle: l10n.commentsSheetSubtitle,
      useModalRouteShape: true,
      trailing: AppCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppActionTile(
              icon: Icons.flag_outlined,
              title: l10n.safetyReportTitle,
              subtitle: l10n.safetyReportDetailsHint,
              onTap: () => Navigator.of(context).pop(CommentPeerAction.report),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppActionTile(
              icon: Icons.block_rounded,
              title: l10n.safetyBlockUserTitle,
              subtitle: l10n.profileBlockedUsersSubtitle,
              tone: AppSurfaceTone.danger,
              onTap: () => Navigator.of(context).pop(CommentPeerAction.block),
            ),
          ],
        ),
      ),
    );
  }
}
