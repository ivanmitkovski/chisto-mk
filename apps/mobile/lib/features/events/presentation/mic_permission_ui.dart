import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_confirm_dialog.dart';

/// In-app rationale before the OS microphone permission sheet (design-system dialog).
Future<bool?> showMicPermissionRationaleDialog(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  return AppConfirmDialog.show(
    context: context,
    title: l10n.micPermissionRationaleTitle,
    body: l10n.micPermissionRationaleBody,
    confirmLabel: l10n.micPermissionRationaleAllow,
    cancelLabel: l10n.micPermissionRationaleNotNow,
    barrierDismissible: true,
  );
}

/// Shown when mic access is permanently denied; confirm opens system Settings.
Future<void> showMicOpenSettingsDialog(BuildContext context) async {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  final bool? open = await AppConfirmDialog.show(
    context: context,
    title: l10n.eventChatMicPermissionDenied,
    body: l10n.micPermissionRationaleBody,
    confirmLabel: l10n.micPermissionOpenSettings,
    cancelLabel: l10n.commonCancel,
    barrierDismissible: true,
  );
  if (open == true) {
    await openAppSettings();
  }
}
