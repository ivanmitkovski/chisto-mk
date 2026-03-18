import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 4;

  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  bool _isLoading = false;
  bool _sendingOtp = false;
  static const int _initialResendSeconds = 45;
  int _secondsRemaining = _initialResendSeconds;
  Timer? _resendTimer;
  bool _hasResentOnce = false;
  String? _apiError;
  String? _devCode;
  int _verifyAttempts = 0;
  bool _otpLocked = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  bool get _isComplete => _codeController.text.trim().length == _otpLength;
  bool get _canResend => _secondsRemaining == 0 && !_isLoading;
  bool get _canSubmit => !_otpLocked && _isComplete && !_isLoading;

  static String _formatPhoneForDisplay(String e164) {
    if (e164.startsWith('+389') && e164.length == 12) {
      return '+389 ${e164.substring(4, 6)} ${e164.substring(6, 9)} ${e164.substring(9)}';
    }
    return e164;
  }

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _requestOtp();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
  }

  Future<void> _requestOtp() async {
    if (_sendingOtp) return;
    setState(() {
      _sendingOtp = true;
      _apiError = null;
    });
    try {
      final SendOtpResult result = await ServiceLocator.instance.authRepository
          .requestOtp(widget.phoneNumber);
      if (!mounted) return;
      setState(() {
        _devCode = result.devCode;
        _sendingOtp = false;
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = messageForAuthError(e);
        _sendingOtp = false;
      });
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = _initialResendSeconds);
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
    AppHaptics.tap();
    setState(() {});

    if (_isComplete && !_isLoading && !_otpLocked) {
      _onContinue();
    }
  }

  Future<void> _onContinue() async {
    if (!_isComplete || _isLoading || _otpLocked) return;

    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      await ServiceLocator.instance.authRepository.verifyOtp(
        widget.phoneNumber,
        _codeController.text.trim(),
      );
      if (!mounted) return;
      AppHaptics.success();
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.location,
        (Route<dynamic> route) => false,
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'OTP_INVALID') {
          _verifyAttempts += 1;
          if (_verifyAttempts >= 3) {
            _otpLocked = true;
            _codeController.clear();
            _apiError = 'Too many wrong codes. Request a new code.';
          } else {
            _apiError = messageForAuthError(e);
          }
        } else {
          _apiError = messageForAuthError(e);
        }
      });
      AppHaptics.warning();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) {
      AppHaptics.tap();
      return;
    }
    AppHaptics.light();
    _codeController.clear();
    _codeFocusNode.requestFocus();
    setState(() {
      _hasResentOnce = true;
      _verifyAttempts = 0;
      _otpLocked = false;
      _apiError = null;
    });
    _startResendCountdown();
    await _requestOtp();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

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
                duration: AppMotion.medium,
                curve: AppMotion.emphasized,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: 'Go back',
                        child: const AppBackButton(),
                      ),
                      if (_apiError != null) ...[
                        ApiErrorBanner(
                          message: _apiError!,
                          onDismiss: () => setState(() => _apiError = null),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_devCode != null) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.radius14),
                            ),
                            child: Text(
                              'Your code: $_devCode',
                              style: AppTypography.authSubtitle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      Center(
                        child: ClipRRect(
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
                      ),
                      const SizedBox(height: AppSpacing.radius22),
                      const Center(
                        child: Text(
                          'Enter code',
                          style: AppTypography.authHeadline,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: Text(
                          'We just sent a 4‑digit code to ${_formatPhoneForDisplay(widget.phoneNumber)}',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.authSubtitle,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radiusPill),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _codeFocusNode.requestFocus(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List<Widget>.generate(
                            _otpLength,
                            (int index) {
                              final String text = index < _codeController.text.length
                                  ? _codeController.text[index]
                                  : '';
                              final bool isActive =
                                  index == _codeController.text.length && !_isComplete;

                              return _OtpDigitBox(
                                value: text,
                                isActive: isActive,
                              );
                            },
                          ),
                        ),
                      ),
                      // Hidden text field that owns the real input & keyboard.
                      SizedBox(
                        height: 0,
                        width: 0,
                        child: TextField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[AutofillHints.oneTimeCode],
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_otpLength),
                          ],
                          onChanged: _handleCodeChanged,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radiusPill),
                      Semantics(
                        button: true,
                        label: 'Continue',
                        child: PrimaryButton(
                          label: 'Continue',
                          enabled: _isComplete && !_isLoading,
                          onPressed: _canSubmit ? _onContinue : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: _canResend ? _handleResend : null,
                          child: AnimatedSwitcher(
                            duration: AppMotion.fast,
                            child: _canResend
                                ? const Text.rich(
                                    key: ValueKey('resend-active'),
                                    TextSpan(
                                      text: 'Didn’t receive code? ',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 17,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Send again',
                                          style: TextStyle(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    key: const ValueKey('resend-countdown'),
                                    'Resend code in ${_secondsRemaining}s',
                                    style: AppTypography.authSubtitle,
                                  ),
                          ),
                        ),
                      ),
                      if (_hasResentOnce) ...<Widget>[
                        const SizedBox(height: AppSpacing.radiusSm),
                        Text(
                          'We’ve sent a new code to ${widget.phoneNumber}.',
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

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.value,
    required this.isActive,
  });

  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value.isNotEmpty;

    return AnimatedContainer(
      duration: AppMotion.xFast,
      curve: AppMotion.emphasized,
      width: 72,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: hasValue
              ? AppColors.primaryDark
              : (isActive ? AppColors.primary : AppColors.inputBorder),
          width: hasValue || isActive ? 1.6 : 1.0,
        ),
      ),
      child: Text(
        value,
        style: AppTypography.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
