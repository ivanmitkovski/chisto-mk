import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

abstract final class ProfileActionsHandler {
  static Future<void> handleHelp(BuildContext context) async {
    AppHaptics.tap();
    final String url = ServiceLocator.instance.config.helpCenterUrl;
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppSnack.show(
        context,
        message: 'Could not open help center',
        type: AppSnackType.info,
      );
    }
  }

  static Future<void> handleLogout(BuildContext context) async {
    AppHaptics.tap();
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in anytime with your account.',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      _performLogout(context);
    }
  }

  static Future<void> handleDeleteAccount(BuildContext context) async {
    AppHaptics.tap();
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'All your data will be permanently removed. This action cannot be undone.',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!context.mounted) return;
      final bool? doubleConfirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => CupertinoAlertDialog(
          title: const Text('Permanently delete?'),
          content: const Text(
            'Your account and all associated data will be permanently deleted.',
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete account'),
            ),
          ],
        ),
      );
      if (doubleConfirm == true && context.mounted) {
        _performLogout(context);
        if (context.mounted) {
          AppSnack.show(
            context,
            message: 'Account deletion requested',
            type: AppSnackType.info,
          );
        }
      }
    }
  }

  static Future<void> _performLogout(BuildContext context) async {
    await ServiceLocator.instance.authRepository.signOut();
    AppHaptics.success();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (Route<dynamic> route) => false,
    );
  }
}
