import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';

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
  return verify == true;
}

/// Opens [OtpScreen] and requests an SMS code on entry.
Future<void> pushPhoneVerificationOtp(
  BuildContext context,
  String phoneNumberE164,
) {
  return Navigator.of(context).pushNamed(
    AppRoutes.otp,
    arguments: OtpRouteArgs(
      phoneNumberE164: phoneNumberE164,
      requestOtpOnOpen: true,
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
      await pushPhoneVerificationOtp(context, phoneNumberE164);
    }
  } else if (context.mounted) {
    await showPhoneNotVerifiedDialog(context);
  }
  return true;
}
