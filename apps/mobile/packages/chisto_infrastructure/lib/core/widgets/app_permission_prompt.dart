import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helpers for showing a consistent permission-denied prompt that routes the
/// user to the OS app settings when the permission is permanently denied.
///
/// The actual permission request is the caller's responsibility — this helper
/// only handles the UX *after* the OS has answered `denied` or `deniedForever`.
class AppPermissionPrompt {
  AppPermissionPrompt._();

  /// Shows the design-system confirm dialog asking the user to open the system
  /// Settings app and grant the permission. Returns `true` if Settings was
  /// launched (the caller should re-check the permission on app resume).
  static Future<bool> showOpenSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String cancelLabel,
    required String openSettingsLabel,
  }) async {
    final bool? confirmed = await AppConfirmDialog.show(
      context: context,
      title: title,
      body: message,
      confirmLabel: openSettingsLabel,
      cancelLabel: cancelLabel,
    );
    if (confirmed ?? false) {
      return openAppSettings();
    }
    return false;
  }
}
