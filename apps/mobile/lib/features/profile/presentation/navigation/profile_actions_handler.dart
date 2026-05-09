import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

abstract final class ProfileActionsHandler {
  static Future<void> handleHelp(BuildContext context) async {
    AppHaptics.tap();
    final String url = ServiceLocator.instance.config.helpCenterUrl;
    final Uri uri = Uri.parse(url);
    final bool launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.profileHelpCenterOpenFailedSnack,
        type: AppSnackType.info,
      );
    }
  }

  static Future<void> handleLogout(BuildContext context) async {
    AppHaptics.tap();
    final l10n = context.l10n;
    final bool? confirm = await AppConfirmDialog.show(
      context: context,
      title: l10n.profileSignOutDialogTitle,
      body: l10n.profileSignOutDialogBody,
      confirmLabel: l10n.profileSignOutTile,
      cancelLabel: l10n.commonCancel,
      isDestructive: false,
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ServiceLocator.instance.authRepository.signOut();
      AppHaptics.success();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.signIn,
        (Route<dynamic> route) => false,
      );
    } on AppError catch (e) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: e.message,
        type: AppSnackType.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: l10n.profileSignOutFailedSnack,
        type: AppSnackType.error,
      );
    }
  }

  static Future<void> handleDeleteAccount(BuildContext context) async {
    AppHaptics.tap();
    final l10n = context.l10n;

    final bool? warned = await AppConfirmDialog.show(
      context: context,
      title: l10n.profileDeleteAccountDialogTitle,
      body: l10n.profileDeleteAccountDialogBody,
      confirmLabel: l10n.commonContinue,
      cancelLabel: l10n.commonCancel,
      isDestructive: true,
    );
    if (warned != true || !context.mounted) return;

    final bool? typedConfirm = await AppConfirmDialog.show(
      context: context,
      title: l10n.profileDeleteAccountTypeConfirmTitle,
      body: l10n.profileDeleteAccountTypeConfirmBody,
      confirmLabel: l10n.profileDeleteAccountTile,
      cancelLabel: l10n.commonCancel,
      isDestructive: true,
      barrierDismissible: false,
      typeToConfirm: l10n.profileDeleteAccountConfirmPhrase,
      typedFieldPlaceholder: l10n.profileDeleteAccountTypeFieldPlaceholder,
      typedMismatchMessage: l10n.profileDeleteAccountTypeMismatchSnack,
    );
    if (typedConfirm != true || !context.mounted) return;

    try {
      await ServiceLocator.instance.authRepository.deleteAccount();
      AppHaptics.success();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.signIn,
        (Route<dynamic> route) => false,
      );
    } on AppError catch (e) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: e.message,
        type: AppSnackType.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: l10n.profileDeleteAccountFailedSnack,
        type: AppSnackType.error,
      );
    }
  }
}
