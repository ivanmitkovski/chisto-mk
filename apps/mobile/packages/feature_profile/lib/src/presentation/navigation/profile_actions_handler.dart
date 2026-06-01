import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class ProfileActionsHandler {
  static Future<void> openExternalUrl(
    BuildContext context,
    String url, {
    required String failedSnackMessage,
  }) async {
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      AppSnack.show(
        context,
        message: failedSnackMessage,
        type: AppSnackType.info,
      );
    }
  }

  static Future<void> handlePrivacyPolicy(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final String failedSnack = context.l10n.profilePrivacyPolicyOpenFailedSnack;
    await openExternalUrl(
      context,
      ref.read(appConfigProvider).privacyUrl,
      failedSnackMessage: failedSnack,
    );
  }

  static Future<void> handleTerms(BuildContext context, WidgetRef ref) async {
    final String failedSnack = context.l10n.profileTermsOpenFailedSnack;
    await openExternalUrl(
      context,
      ref.read(appConfigProvider).termsUrl,
      failedSnackMessage: failedSnack,
    );
  }

  static Future<void> handleSafetyReport(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final String? userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null || userId.isEmpty) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: l10n.safetyReportFailed,
        type: AppSnackType.error,
      );
      return;
    }
    await showUgcReportSheet(
      context,
      subjectType: 'safety_issue',
      subjectId: userId,
      title: l10n.profileSafetyReportIssueTile,
    );
  }

  static Future<void> handleHelp(BuildContext context, WidgetRef ref) async {
    final String failedSnack = context.l10n.profileHelpCenterOpenFailedSnack;
    await openExternalUrl(
      context,
      ref.read(appConfigProvider).helpCenterUrl,
      failedSnackMessage: failedSnack,
    );
  }

  static Future<void> handleLogout(BuildContext context, WidgetRef ref) async {
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
      await ref.read(authRepositoryProvider).signOut();
      if (!context.mounted) return;
      AppNavigation.goSignInAndClearStack();
    } on AppError catch (e) {
      if (!context.mounted) return;
      AppSnack.show(context, message: e.message, type: AppSnackType.error);
    } catch (_) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: l10n.profileSignOutFailedSnack,
        type: AppSnackType.error,
      );
    }
  }

  static Future<void> handleDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!context.mounted) return;
      AppNavigation.goSignInAndClearStack();
    } on AppError catch (e) {
      if (!context.mounted) return;
      AppSnack.show(context, message: e.message, type: AppSnackType.error);
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
