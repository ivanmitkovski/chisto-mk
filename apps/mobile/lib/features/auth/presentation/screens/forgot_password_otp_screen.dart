import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key, required this.phoneNumberE164});

  final String phoneNumberE164;

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  static const int _otpLength = 4;

  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  bool _isLoading = false;
  static const int _initialResendSeconds = 45;
  int _secondsRemaining = _initialResendSeconds;
  Timer? _resendTimer;
  String? _apiError;

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
      if (mounted) _codeFocusNode.requestFocus();
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
    AppHaptics.tap(context);
    setState(() {});
    if (_isComplete && !_isLoading) _onContinue();
  }

  Future<void> _onContinue() async {
    if (!_isComplete) return;

    setState(() => _isLoading = true);
    final Duration delay = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.standard;
    await Future<void>.delayed(delay);
    if (!mounted) return;

    setState(() => _isLoading = false);
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
    AppHaptics.light(context);
    setState(() => _isLoading = true);
    setState(() => _apiError = null);
    try {
      await ServiceLocator.instance.authRepository.requestPasswordReset(
        widget.phoneNumberE164,
      );
      if (!mounted) return;
      _codeController.clear();
      _codeFocusNode.requestFocus();
      _startResendCountdown();
    } on AppError catch (e) {
      if (!mounted) return;
      setState(
        () => _apiError =
            messageForAuthError(AppLocalizations.of(context)!, e),
      );
      _startResendCountdown();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
                      if (_apiError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ApiErrorBanner(
                          message: _apiError!,
                          onDismiss: () => setState(() => _apiError = null),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        l10n.authForgotPasswordOtpTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.authForgotPasswordOtpSubtitle(
                          formatPhoneForDisplay(widget.phoneNumberE164),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radiusPill),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _codeFocusNode.requestFocus(),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List<Widget>.generate(
                              _otpLength,
                              (int index) {
                                final String text =
                                    index < _codeController.text.length
                                        ? _codeController.text[index]
                                        : '';
                                final bool isActive =
                                    index == _codeController.text.length &&
                                        !_isComplete;

                                return _OtpDigitBox(
                                  value: text,
                                  isActive: isActive,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 0,
                        width: 0,
                        child: Semantics(
                          label: l10n.authOtpCodeSemantic,
                          textField: true,
                          child: TextField(
                            controller: _codeController,
                            focusNode: _codeFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[
                              AutofillHints.oneTimeCode,
                            ],
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(_otpLength),
                            ],
                            onChanged: _handleCodeChanged,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radiusPill),
                      Semantics(
                        button: true,
                        label: l10n.authOtpContinue,
                        child: PrimaryButton(
                          label: l10n.authOtpContinue,
                          enabled: _isComplete && !_isLoading,
                          onPressed: _isLoading ? null : _onContinue,
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
                                      children: [
                                        TextSpan(
                                          text: l10n.authOtpResendAction,
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
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
    final Duration animDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.xFast;

    return AnimatedContainer(
      duration: animDuration,
      curve: AppMotion.emphasized,
      width: 72,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radius14),
        border: Border.all(
          color: hasValue
              ? AppColors.primaryDark
              : (isActive ? AppColors.primary : AppColors.divider),
          width: hasValue || isActive ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
