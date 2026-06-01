import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum AuthOtpResendStyle { registration, passwordReset }

/// Shared resend / countdown control for OTP screens.
class AuthOtpResendButton extends StatelessWidget {
  const AuthOtpResendButton({
    super.key,
    required this.l10n,
    required this.canResend,
    required this.secondsRemaining,
    required this.onResend,
    this.style = AuthOtpResendStyle.registration,
  });

  final AppLocalizations l10n;
  final bool canResend;
  final int secondsRemaining;
  final VoidCallback? onResend;
  final AuthOtpResendStyle style;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: canResend ? onResend : null,
        child: AnimatedSwitcher(
          duration: disableAnimations ? Duration.zero : AppMotion.fast,
          child: canResend
              ? Text.rich(
                  key: const ValueKey<String>('resend-active'),
                  TextSpan(
                    text: l10n.authOtpResendPrefix,
                    style: _prefixStyle(context),
                    children: <InlineSpan>[
                      TextSpan(
                        text: l10n.authOtpResendAction,
                        style: AppTypography.authTextLink(textTheme),
                      ),
                    ],
                  ),
                )
              : Text(
                  key: const ValueKey<String>('resend-countdown'),
                  l10n.authOtpResendCountdown(secondsRemaining),
                  style: _countdownStyle(context),
                ),
        ),
      ),
    );
  }

  TextStyle? _prefixStyle(BuildContext context) {
    return switch (style) {
      AuthOtpResendStyle.registration =>
        AppTypography.textTheme.bodyLarge!.copyWith(
          color: AppColors.textPrimary,
          fontSize: 17,
        ),
      AuthOtpResendStyle.passwordReset => Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
    };
  }

  TextStyle? _countdownStyle(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return switch (style) {
      AuthOtpResendStyle.registration => AppTypography.authSubtitle(textTheme),
      AuthOtpResendStyle.passwordReset => Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
    };
  }
}
