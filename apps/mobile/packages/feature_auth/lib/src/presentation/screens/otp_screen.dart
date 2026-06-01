import 'dart:async';

import 'package:chisto_infrastructure/core/assets/app_assets.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/loading_overlay.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/registration_otp_controller.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/constants/auth_otp_constants.dart';
import 'package:feature_auth/src/presentation/eula_acceptance_flow.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_input.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_resend_button.dart';
import 'package:feature_auth/src/presentation/widgets/auth_otp_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.requestOtpOnOpen = false,
  });

  final String phoneNumber;

  /// When `true`, calls `/auth/otp/send` once on open (e.g. unverified sign-in).
  final bool requestOtpOnOpen;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  int _secondsRemaining = kAuthOtpResendSeconds;
  Timer? _resendTimer;
  bool _hasResentOnce = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  bool get _isComplete => _codeController.text.trim().length == kAuthOtpLength;
  RegistrationOtpState get _otpState =>
      ref.watch(registrationOtpControllerProvider);

  bool get _isLoading => _otpState.isLoading;
  bool get _sendingOtp => _otpState.sendingOtp;
  bool get _otpLocked => _otpState.otpLocked;

  bool get _canResend => _secondsRemaining == 0 && !_isLoading;
  bool get _canSubmit => !_otpLocked && _isComplete && !_isLoading;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _codeFocusNode.requestFocus();
      if (widget.requestOtpOnOpen) {
        unawaited(_requestOtp());
      }
    });
  }

  Future<void> _requestOtp() async {
    await ref
        .read(registrationOtpControllerProvider.notifier)
        .requestOtp(widget.phoneNumber);
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
    if (value.length == kAuthOtpLength) {
      AppHaptics.tap(context);
    }
    setState(() {});

    if (_isComplete && !_isLoading && !_otpLocked) {
      _onContinue();
    }
  }

  Future<void> _onContinue() async {
    if (!_isComplete || _isLoading || _otpLocked) return;

    try {
      await ref
          .read(registrationOtpControllerProvider.notifier)
          .verifyOtp(widget.phoneNumber, _codeController.text.trim());
      if (!mounted) return;
      AppHaptics.success(context);
      final bool accepted = await ensureCommunityGuidelinesAccepted(
        context,
        ref,
      );
      if (!accepted || !mounted) return;
      AppNavigation.goLocation();
    } on AppError {
      if (!mounted) return;
      if (_otpLocked) {
        _codeController.clear();
      }
      AppHaptics.warning(context);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) {
      return;
    }
    _codeController.clear();
    _codeFocusNode.requestFocus();
    setState(() => _hasResentOnce = true);
    ref.read(registrationOtpControllerProvider.notifier).resetAttempts();
    _startResendCountdown();
    await _requestOtp();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final RegistrationOtpState otpState = _otpState;
    final String? apiError = otpState.otpLocked
        ? l10n.authErrorOtpMaxAttempts
        : otpState.error != null
        ? messageForAuthError(l10n, otpState.error!)
        : null;

    return AuthOtpScaffold(
      leading: const AppBackButton(),
      errorBanner: apiError != null
          ? ApiErrorBanner(
              message: apiError,
              onDismiss: () => ref
                  .read(registrationOtpControllerProvider.notifier)
                  .clearError(),
            )
          : null,
      headerIllustration: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radius22),
        child: SizedBox(
          width: 146,
          height: 146,
          child: SvgPicture.asset(
            AppAssets.otpIllustration,
            fit: BoxFit.contain,
          ),
        ),
      ),
      headerCentered: true,
      title: l10n.authOtpTitle,
      subtitle: l10n.authOtpSubtitle(formatPhoneForDisplay(widget.phoneNumber)),
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
          enabled: _isComplete && !_isLoading,
          onPressed: _canSubmit ? _onContinue : null,
        ),
      ),
      resendButton: AuthOtpResendButton(
        l10n: l10n,
        canResend: _canResend,
        secondsRemaining: _secondsRemaining,
        onResend: _handleResend,
      ),
      footer: _hasResentOnce
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.radiusSm),
              child: Text(
                l10n.authOtpResentMessage(widget.phoneNumber),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardSubtitle(textTheme),
              ),
            )
          : null,
      loadingOverlay: LoadingOverlay(visible: _isLoading || _sendingOtp),
    );
  }
}
