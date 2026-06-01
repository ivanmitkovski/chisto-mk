import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:feature_safety/src/application/safety_providers.dart';
import 'package:feature_safety/src/data/ugc_moderation_repository.dart';
import 'package:feature_safety/src/domain/safety_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final ProviderContainer container = ProviderScope.containerOf(context);
  final String? selfId = container.read(authRepositoryProvider).currentUserId;
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

  final l10n = context.l10n;
  final bool? confirmed = await AppConfirmDialog.show(
    context: context,
    title: l10n.safetyBlockUserTitle,
    body: l10n.safetyBlockUserBody(displayName),
    confirmLabel: l10n.safetyBlockUserConfirm,
    cancelLabel: l10n.commonCancel,
    isDestructive: true,
  );
  if (confirmed != true || !context.mounted) {
    return false;
  }

  final UgcModerationRepository repo =
      repository ?? container.read(ugcModerationRepositoryProvider);
  final BlockUserUseCase blockUser = BlockUserUseCase(repository: repo);
  try {
    final BlockUserOutcome outcome = await blockUser.call(
      blockedUserId: id,
      currentUserId: selfId,
    );
    if (outcome != BlockUserOutcome.success) {
      return false;
    }
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
