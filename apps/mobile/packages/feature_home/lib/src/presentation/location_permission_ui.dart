import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/widgets/app_permission_prompt.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:flutter/material.dart';

/// Returns `true` when the OS has blocked location (services off or permission denied).
Future<bool> isLocationAccessBlocked(LocationService geo) async {
  if (!await geo.isLocationServiceEnabled()) {
    return true;
  }
  final AppLocationPermission permission = await geo.checkPermission();
  return permission == AppLocationPermission.denied ||
      permission == AppLocationPermission.deniedForever;
}

Future<void> showLocationOpenSettingsDialog(BuildContext context) async {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  await AppPermissionPrompt.showOpenSettingsDialog(
    context,
    title: l10n.locationPermissionOpenSettingsTitle,
    message: l10n.locationPermissionOpenSettingsBody,
    cancelLabel: l10n.commonCancel,
    openSettingsLabel: l10n.locationPermissionOpenSettingsAction,
  );
}

void showLocationPermissionDeniedSnack(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  AppSnack.show(
    context,
    message: l10n.locationPermissionDeniedSnack,
    type: AppSnackType.warning,
    actionLabel: l10n.locationPermissionOpenSettingsAction,
    onAction: () => showLocationOpenSettingsDialog(context),
  );
}

void showMapLocateFailedSnack(
  BuildContext context, {
  required bool permissionBlocked,
}) {
  if (permissionBlocked) {
    showLocationPermissionDeniedSnack(context);
    return;
  }
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  AppSnack.show(
    context,
    message: l10n.mapLocateFailedSnack,
    type: AppSnackType.warning,
  );
}
