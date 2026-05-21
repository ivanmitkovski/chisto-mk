import 'dart:async';

import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/features/auth/application/password_reset_otp_controller.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_otp_constants.dart';
import 'package:chisto_mobile/features/auth/presentation/widgets/auth_otp_input.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/organisms/auth_screen_header.dart';
import 'package:chisto_mobile/shared/widgets/organisms/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  const ForgotPasswordOtpScreen({super.key, required this.phoneNumberE164});

  final String phoneNumberE164;

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  int _secondsRemaining = kAuthOtpResendSeconds;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _codeController.text.trim().length == kAuthOtpLength;

  PasswordResetOtpState get _otpState =>
      ref.watch(passwordResetOtpControllerProvider);

  bool get _isLoading => _otpState.isLoading;
  bool get _otpLocked => _otpState.otpLocked;

  bool get _canResend => _secondsRemaining == 0 && !_isLoading;

  String? get _apiErrorMessage {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_otpState.otpLocked) return l10n.authErrorOtpMaxAttempts;
    final AppError? error = _otpState.error;
    if (error == null) return null;
    return messageForAuthError(l10n, error);
  }

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocusNode.requestFocus();
    });
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = kAuthOtpResendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        setState(() => _secondsRemaining = 0);
        timer.cancel();
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  void _handleCodeChanged(String value) {
    ref.read(passwordResetOtpControllerProvider.notifier).clearError();
    if (value.length == kAuthOtpLength) {
      AppHaptics.tap(context);
    }
    setState(() {});
    if (_isComplete && !_isLoading && !_otpLocked) {
      unawaited(_onContinue());
    }
  }

  Future<void> _onContinue() async {
    if (!_isComplete || _isLoading || _otpLocked) return;

    final Duration delay = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.standard;
    await Future<void>.delayed(delay);
    if (!mounted) return;

    try {
      await ref.read(passwordResetOtpControllerProvider.notifier).verifyCode(
            widget.phoneNumberE164,
            _codeController.text.trim(),
          );
    } on AppError {
      if (!mounted) return;
      if (_otpLocked) {
        _codeController.clear();
      }
      AppHaptics.warning(context);
      return;
    }

    if (!mounted) return;
    AppHaptics.success(context);

    Navigator.of(context).pushNamed(
      AppRoutes.forgotPasswordNew,
      arguments: ForgotPasswordNewRouteArgs(
        phoneNumberE164: widget.phoneNumberE164,
        code: _codeController.text.trim(),
      ),
    );
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    try {
      await ref
          .read(passwordResetOtpControllerProvider.notifier)
          .resend(widget.phoneNumberE164);
      if (!mounted) return;
      ref.read(passwordResetOtpControllerProvider.notifier).resetAttempts();
      _codeController.clear();
      _codeFocusNode.requestFocus();
      _startResendCountdown();
    } on AppError {
      if (!mounted) return;
      _startResendCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final String? apiError = _apiErrorMessage;

    return Stack(
      children: <Widget>[
        Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColors.panelBackground,
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: AnimatedPadding(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.medium,
                curve: AppMotion.emphasized,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppBackButton(),
                      if (apiError != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        ApiErrorBanner(
                          message: apiError,
                          onDismiss: () => ref
                              .read(passwordResetOtpControllerProvider.notifier)
                              .clearError(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      AuthScreenHeader(
                        title: l10n.authForgotPasswordOtpTitle,
                        subtitle: l10n.authForgotPasswordOtpSubtitle(
                          formatPhoneForDisplay(widget.phoneNumberE164),
                        ),
                        subtitleMaxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.radiusPill),
                      AuthOtpInput(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        semanticsLabel: l10n.authOtpCodeSemantic,
                        onChanged: _handleCodeChanged,
                        enabled: !_otpLocked && !_isLoading,
                      ),
                      const SizedBox(height: AppSpacing.radiusPill),
                      Semantics(
                        button: true,
                        label: l10n.authOtpContinue,
                        child: PrimaryButton(
                          label: l10n.authOtpContinue,
                          enabled: _isComplete && !_isLoading && !_otpLocked,
                          onPressed: _isLoading || _otpLocked ? null : _onContinue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: _canResend ? _handleResend : null,
                          child: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : AppMotion.fast,
                            child: _canResend
                                ? Text.rich(
                                    key: const ValueKey<String>('resend-active'),
                                    TextSpan(
                                      text: l10n.authOtpResendPrefix,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: l10n.authOtpResendAction,
                                          style: AppTypography.authTextLink,
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    key: const ValueKey<String>(
                                      'resend-countdown',
                                    ),
                                    l10n.authOtpResendCountdown(
                                      _secondsRemaining,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        LoadingOverlay(visible: _isLoading),
      ],
    );
  }
}
