import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/safety/data/ugc_moderation_repository.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:flutter/material.dart';

/// Confirms and blocks a user via `POST /users/me/blocks`.
Future<bool> confirmAndBlockUser(
  BuildContext context, {
  required String blockedUserId,
  required String displayName,
  UgcModerationRepository? repository,
}) async {
  final String id = blockedUserId.trim();
  if (id.isEmpty) {
    return false;
  }
  final String? selfId = AppBootstrap.instance.authRepository.currentUserId;
  if (selfId != null && selfId == id) {
    if (context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.safetyBlockUserSelfSnack,
        type: AppSnackType.warning,
      );
    }
    return false;
  }

  final bool? confirmed = await AppConfirmDialog.show(
    context: context,
    title: context.l10n.safetyBlockUserTitle,
    body: context.l10n.safetyBlockUserBody(displayName),
    confirmLabel: context.l10n.safetyBlockUserConfirm,
    cancelLabel: context.l10n.commonCancel,
    isDestructive: true,
  );
  if (confirmed != true || !context.mounted) {
    return false;
  }

  final UgcModerationRepository repo =
      repository ?? UgcModerationRepository();
  try {
    await repo.blockUser(id);
    if (!context.mounted) {
      return true;
    }
    AppSnack.show(
      context,
      message: context.l10n.safetyBlockUserSuccess,
      type: AppSnackType.success,
    );
    return true;
  } on AppError {
    if (!context.mounted) {
      return false;
    }
    AppSnack.show(
      context,
      message: context.l10n.safetyBlockUserFailed,
      type: AppSnackType.error,
    );
    return false;
  } on Object {
    if (!context.mounted) {
      return false;
    }
    AppSnack.show(
      context,
      message: context.l10n.safetyBlockUserFailed,
      type: AppSnackType.error,
    );
    return false;
  }
}
