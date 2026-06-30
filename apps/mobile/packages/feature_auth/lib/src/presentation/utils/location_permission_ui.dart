import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/widgets/app_permission_prompt.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ensures location services are on and permission is granted (prompts when denied).
Future<bool> ensureLocationPermissionForGate({
  required BuildContext context,
  required LocationService location,
}) async {
  if (!await location.isLocationServiceEnabled()) {
    return false;
  }

  AppLocationPermission permission = await location.checkPermission();
  if (permission == AppLocationPermission.deniedForever) {
    if (context.mounted) {
      await showLocationOpenSettingsDialog(context);
    }
    return false;
  }

  if (permission == AppLocationPermission.denied) {
    permission = await location.requestPermission();
    if (permission == AppLocationPermission.deniedForever) {
      if (context.mounted) {
        await showLocationOpenSettingsDialog(context);
      }
      return false;
    }
    if (permission != AppLocationPermission.whileInUse &&
        permission != AppLocationPermission.always) {
      return false;
    }
  }

  return permission == AppLocationPermission.whileInUse ||
      permission == AppLocationPermission.always;
}

Future<void> showLocationOpenSettingsDialog(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  return AppPermissionPrompt.showOpenSettingsDialog(
    context,
    title: l10n.locationPermissionOpenSettingsTitle,
    message: l10n.locationPermissionOpenSettingsBody,
    cancelLabel: l10n.commonCancel,
    openSettingsLabel: l10n.locationPermissionOpenSettingsAction,
  );
}
