import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// In-app rationale before the OS notification permission sheet (design-system dialog).
Future<void> showPushPermissionRationaleDialog(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  return AppConfirmDialog.show(
    context: context,
    title: l10n.pushPermissionRationaleTitle,
    body: l10n.pushPermissionRationaleBody,
    confirmLabel: l10n.pushPermissionRationaleAllow,
    cancelLabel: l10n.pushPermissionRationaleNotNow,
    barrierDismissible: true,
  ).then((_) {});
}

/// Prompt to open OS app settings when notification permission was permanently denied.
Future<void> showPushOpenSettingsDialog(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  return AppConfirmDialog.show(
    context: context,
    title: l10n.pushPermissionOpenSettingsTitle,
    body: l10n.pushPermissionOpenSettingsBody,
    confirmLabel: l10n.pushPermissionOpenSettingsAction,
    cancelLabel: l10n.pushPermissionRationaleNotNow,
    barrierDismissible: true,
  ).then((bool? open) async {
    if (open ?? false) {
      await openAppSettings();
    }
  });
}
