import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helpers for showing a consistent permission-denied prompt that routes the
/// user to the OS app settings when the permission is permanently denied.
///
/// The actual permission request is the caller's responsibility — this helper
/// only handles the UX *after* the OS has answered `denied` or `deniedForever`.
class AppPermissionPrompt {
  AppPermissionPrompt._();

  /// Shows a Material AlertDialog asking the user to open the system Settings
  /// app and grant the permission. Returns `true` if Settings was launched
  /// (the caller should re-check the permission on app resume).
  static Future<bool> showOpenSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String cancelLabel,
    required String openSettingsLabel,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              openSettingsLabel,
              style: AppTypography.pillLabel(
                Theme.of(ctx).textTheme,
              ).copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      return openAppSettings();
    }
    return false;
  }

  /// Same as [showOpenSettingsDialog] but using Cupertino styling for parity
  /// on iOS-leaning sheets.
  static Future<bool> showCupertinoOpenSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String cancelLabel,
    required String openSettingsLabel,
  }) async {
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(openSettingsLabel),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      return openAppSettings();
    }
    return false;
  }
}
