import 'package:flutter/material.dart';

import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_confirm_dialog.dart';

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
