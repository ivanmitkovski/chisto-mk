import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/location/device_location_reader.dart';
import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/location/macedonia_bounds.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design-system dialog when sign-in or a guarded action requires phone verification.
///
/// Returns `true` if the user chose to verify.
Future<bool> showPhoneNotVerifiedDialog(BuildContext context) async {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  final bool? verify = await AppConfirmDialog.show(
    context: context,
    title: l10n.authPhoneNotVerified,
    body: l10n.authErrorPhoneNotVerified,
    confirmLabel: l10n.authVerifyPhoneCta,
    cancelLabel: l10n.commonCancel,
  );
  return verify ?? false;
}

/// Opens [OtpScreen] as the primary route and requests an SMS code on entry.
void startPhoneVerificationOtp(
  String phoneNumberE164, {
  bool rememberMe = true,
}) {
  AppNavigation.goOtp(
    OtpRouteArgs(
      phoneNumberE164: phoneNumberE164,
      requestOtpOnOpen: true,
      rememberMe: rememberMe,
    ),
  );
}

/// Handles [PHONE_NOT_VERIFIED] from guarded API calls (reports, events).
///
/// Returns `true` if the error was handled (caller should stop).
Future<bool> handlePhoneNotVerifiedGuardError(
  BuildContext context,
  AppError error, {
  String? phoneNumberE164,
}) async {
  if (error.code != 'PHONE_NOT_VERIFIED') return false;

  AppSnack.show(
    context,
    message: AppLocalizations.of(context)!.authErrorPhoneNotVerified,
    type: AppSnackType.warning,
  );

  if (phoneNumberE164 != null &&
      phoneNumberE164.isNotEmpty &&
      context.mounted) {
    final bool verify = await showPhoneNotVerifiedDialog(context);
    if (verify && context.mounted) {
      startPhoneVerificationOtp(phoneNumberE164);
    }
  } else if (context.mounted) {
    await showPhoneNotVerifiedDialog(context);
  }
  return true;
}

/// Server content-geofence codes from report submit and event check-in.
const Set<String> kLocationGuardErrorCodes = <String>{
  'REPORT_LOCATION_OUTSIDE_MACEDONIA',
  'CHECK_IN_LOCATION_OUTSIDE_MACEDONIA',
};

typedef ProviderRead = T Function<T>(ProviderListenable<T> provider);

/// Best-effort silent GPS check before a location-restricted action.
///
/// Blocks only when permission is already granted and the fix is confidently
/// outside Macedonia. Never prompts; never blocks on GPS failure.
Future<bool> ensureLocationEligibleForAction(
  BuildContext context,
  WidgetRef ref,
) {
  return ensureLocationEligibleForActionWithRead(context, ref.read);
}

Future<bool> ensureLocationEligibleForActionWithRead(
  BuildContext context,
  ProviderRead read,
) async {
  final LocationService location = read(appBootstrapProvider).locationService;

  final AppLocationPermission permission = await location.checkPermission();
  if (permission != AppLocationPermission.whileInUse &&
      permission != AppLocationPermission.always) {
    return true;
  }
  if (!await location.isLocationServiceEnabled()) {
    return true;
  }

  final GeoPosition? fix = await readDeviceLocationFix(
    location,
    timeLimit: const Duration(seconds: 5),
  );
  if (fix == null || !context.mounted) {
    return true;
  }
  if (isWithinMacedonia(fix.latitude, fix.longitude)) {
    return true;
  }

  final AppLocalizations l10n = AppLocalizations.of(context)!;
  AppSnack.show(
    context,
    message: l10n.authLocationActionOnlyInMacedoniaSnack,
    type: AppSnackType.warning,
  );
  return false;
}

/// Handles content-geofence errors from guarded API calls (reports, events).
///
/// Returns `true` if the error was handled (caller should stop).
Future<bool> handleLocationGuardError(
  BuildContext context,
  WidgetRef ref,
  AppError error,
) {
  return handleLocationGuardErrorWithRead(context, ref.read, error);
}

Future<bool> handleLocationGuardErrorWithRead(
  BuildContext context,
  ProviderRead read,
  AppError error,
) async {
  if (!kLocationGuardErrorCodes.contains(error.code)) return false;
  if (!context.mounted) return true;
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  AppSnack.show(
    context,
    message: l10n.authLocationActionOnlyInMacedoniaSnack,
    type: AppSnackType.warning,
  );
  return true;
}
