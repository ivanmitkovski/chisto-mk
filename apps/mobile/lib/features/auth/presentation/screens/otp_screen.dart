import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
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
  static const int _initialResendSeconds = 45;
  int _secondsRemaining = _initialResendSeconds;
  Timer? _resendTimer;
  bool _hasResentOnce = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  bool get _isComplete => _codeController.text.trim().length == _otpLength;
  bool get _canResend => _secondsRemaining == 0 && !_isLoading;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
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
    HapticFeedback.selectionClick();
    setState(() {});

    if (_isComplete && !_isLoading) {
      _onContinue();
    }
  }

  Future<void> _onContinue() async {
    if (!_isComplete) {
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    Navigator.of(context).pushNamed(AppRoutes.location);
  }

  void _handleResend() {
    if (!_canResend) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.lightImpact();
    _codeController.clear();
    _codeFocusNode.requestFocus();
    setState(() {
      _hasResentOnce = true;
    });
    _startResendCountdown();
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
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppBackButton(),
                      const SizedBox(height: 40),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
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
                      const SizedBox(height: 26),
                      const Center(
                        child: Text(
                          'Enter code',
                          style: AppTypography.authHeadline,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'We just sent a 4‑digit code to ${widget.phoneNumber}',
                          textAlign: TextAlign.center,
                          style: AppTypography.authSubtitle,
                        ),
                      ),
                      const SizedBox(height: 28),
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
                      const SizedBox(height: 30),
                      PrimaryButton(
                        label: 'Continue',
                        enabled: _isComplete && !_isLoading,
                        onPressed: _isLoading ? null : _onContinue,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: _canResend ? _handleResend : null,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
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
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (_hasResentOnce) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'We’ve sent a new code to ${widget.phoneNumber}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 72,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: hasValue
              ? AppColors.primaryDark
              : (isActive ? AppColors.inputBorder : AppColors.inputBorder),
          width: hasValue || isActive ? 1.6 : 1.0,
        ),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
