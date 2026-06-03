import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/loading_overlay.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/password_reset_otp_controller.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/constants/auth_otp_constants.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_input.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_resend_button.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  const ForgotPasswordOtpScreen({super.key, required this.target});

  final PasswordResetTarget target;

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

  bool get _isComplete => _codeController.text.trim().length == kAuthOtpLength;

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

  String _subtitle(AppLocalizations l10n) {
    if (widget.target.isSms) {
      return l10n.authForgotPasswordOtpSubtitle(
        formatPhoneForDisplay(widget.target.value),
      );
    }
    return l10n.authForgotPasswordOtpEmailSubtitle(widget.target.value);
  }

  Future<void> _onContinue() async {
    if (!_isComplete || _isLoading || _otpLocked) return;

    final Duration delay = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.standard;
    await Future<void>.delayed(delay);
    if (!mounted) return;

    try {
      await ref
          .read(passwordResetOtpControllerProvider.notifier)
          .verifyCode(widget.target, _codeController.text.trim());
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

    await AppNavigation.pushForgotPasswordNew(
      ForgotPasswordNewRouteArgs(
        target: widget.target,
        code: _codeController.text.trim(),
      ),
    );
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    try {
      await ref
          .read(passwordResetOtpControllerProvider.notifier)
          .resend(widget.target);
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
    final String? apiError = _apiErrorMessage;

    return AuthOtpScaffold(
      leading: const AppBackButton(),
      errorBanner: apiError != null
          ? ApiErrorBanner(
              message: apiError,
              onDismiss: () => ref
                  .read(passwordResetOtpControllerProvider.notifier)
                  .clearError(),
            )
          : null,
      title: l10n.authForgotPasswordOtpTitle,
      subtitle: _subtitle(l10n),
      otpInput: AuthOtpInput(
        controller: _codeController,
        focusNode: _codeFocusNode,
        semanticsLabel: l10n.authOtpCodeSemantic,
        onChanged: _handleCodeChanged,
        enabled: !_otpLocked && !_isLoading,
      ),
      continueButton: Semantics(
        button: true,
        label: l10n.authOtpContinue,
        child: AppButton.primary(
          label: l10n.authOtpContinue,
          enabled: _isComplete && !_isLoading && !_otpLocked,
          onPressed: _isLoading || _otpLocked ? null : _onContinue,
        ),
      ),
      resendButton: AuthOtpResendButton(
        l10n: l10n,
        canResend: _canResend,
        secondsRemaining: _secondsRemaining,
        onResend: _handleResend,
        style: AuthOtpResendStyle.passwordReset,
      ),
      loadingOverlay: LoadingOverlay(visible: _isLoading),
    );
  }
}
