import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/features/auth/application/registration_otp_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_otp_constants.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_mobile/features/auth/presentation/eula_acceptance_flow.dart';
import 'package:chisto_mobile/features/auth/presentation/widgets/auth_otp_input.dart';
import 'package:chisto_mobile/shared/widgets/organisms/auth_screen_header.dart';
import 'package:chisto_mobile/shared/widgets/organisms/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';

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

  bool get _isComplete =>
      _codeController.text.trim().length == kAuthOtpLength;
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
      await ref.read(registrationOtpControllerProvider.notifier).verifyOtp(
            widget.phoneNumber,
            _codeController.text.trim(),
          );
      if (!mounted) return;
      AppHaptics.success(context);
      final bool accepted = await ensureCommunityGuidelinesAccepted(context);
      if (!accepted || !mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.location,
        (Route<dynamic> route) => false,
      );
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final RegistrationOtpState otpState = _otpState;
    final String? apiError = otpState.otpLocked
        ? l10n.authErrorOtpMaxAttempts
        : otpState.error != null
            ? messageForAuthError(l10n, otpState.error!)
            : null;

    return Stack(
      children: [
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
                    children: [
                      const AppBackButton(),
                      if (apiError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ApiErrorBanner(
                          message: apiError,
                          onDismiss: () => ref
                              .read(registrationOtpControllerProvider.notifier)
                              .clearError(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      Center(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radius22),
                          child: SizedBox(
                            width: 146,
                            height: 146,
                            child: SvgPicture.asset(
                              AppAssets.otpIllustration,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radius22),
                      AuthScreenHeader(
                        centered: true,
                        title: l10n.authOtpTitle,
                        subtitle: l10n.authOtpSubtitle(
                          formatPhoneForDisplay(widget.phoneNumber),
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
                          enabled: _isComplete && !_isLoading,
                          onPressed: _canSubmit ? _onContinue : null,
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
                                      style: AppTypography.textTheme.bodyLarge!
                                          .copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 17,
                                      ),
                                      children: [
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
                                    style: AppTypography.authSubtitle,
                                  ),
                          ),
                        ),
                      ),
                      if (_hasResentOnce) ...<Widget>[
                        const SizedBox(height: AppSpacing.radiusSm),
                        Text(
                          l10n.authOtpResentMessage(widget.phoneNumber),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardSubtitle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        LoadingOverlay(visible: _isLoading || _sendingOtp),
      ],
    );
  }
}

