import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/field_error_mapping.dart';
import 'package:chisto_infrastructure/shared/forms/form_validation_mixin.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/loading_overlay.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/password_reset_otp_controller.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/constants/auth_otp_constants.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:feature_auth/src/presentation/utils/otp_focus_helper.dart';
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
    extends ConsumerState<ForgotPasswordOtpScreen>
    with FormValidationMixin {
  static const List<String> _fieldOrder = <String>[FormFieldIds.otp];

  final GlobalKey _otpFieldKey = GlobalKey();
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

  Map<String, String? Function()> _validators(AppLocalizations l10n) =>
      <String, String? Function()>{
        FormFieldIds.otp: () =>
            AuthValidators.otpCode(l10n, _codeController.text),
      };

  String? _otpInlineError(AppLocalizations l10n) {
    return AuthValidators.otpInlineError(
      l10n: l10n,
      code: _codeController.text.trim(),
      submitAttempted: submitAttempted,
      serverError: serverFieldError(FormFieldIds.otp),
    );
  }

  @override
  void initState() {
    super.initState();
    registerFormField(
      FormFieldIds.otp,
      focusNode: _codeFocusNode,
      fieldKey: _otpFieldKey,
    );
    _startResendCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ensureOtpKeyboardVisible(_codeFocusNode));
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
    markFieldDirty(FormFieldIds.otp);
    ref.read(passwordResetOtpControllerProvider.notifier).clearError();
    clearServerFieldErrors();
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
    if (_isLoading || _otpLocked) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    markFieldTouched(FormFieldIds.otp);
    setState(() => submitAttempted = true);
    if (await handleInvalidSubmit(
      context,
      l10n,
      _fieldOrder,
      _validators(l10n),
    )) {
      return;
    }

    final Duration delay = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.standard;
    await Future<void>.delayed(delay);
    if (!mounted) return;

    try {
      await ref
          .read(passwordResetOtpControllerProvider.notifier)
          .verifyCode(widget.target, _codeController.text.trim());
    } on AppError catch (e) {
      if (!mounted) return;
      if (_otpLocked) {
        _codeController.clear();
      }
      final Map<String, String> fieldErrors = fieldErrorsFromAppError(e, l10n);
      if (fieldErrors.isNotEmpty) {
        setServerFieldErrors(fieldErrors);
        await focusAndScrollToFirstInvalid(
          context,
          _fieldOrder,
          _validators(l10n),
        );
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
      unawaited(ensureOtpKeyboardVisible(_codeFocusNode));
      _startResendCountdown();
    } on AppError {
      if (!mounted) return;
      _startResendCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? inlineOtpError = _otpInlineError(l10n);
    final String? apiError = _otpLocked
        ? l10n.authErrorOtpMaxAttempts
        : _otpState.error != null
        ? authBannerMessageForError(
            l10n,
            _otpState.error!,
            displayedFieldIds: registeredFieldIds,
          )
        : null;

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
      otpInput: KeyedSubtree(
        key: _otpFieldKey,
        child: AuthOtpInput(
          controller: _codeController,
          focusNode: _codeFocusNode,
          semanticsLabel: l10n.authOtpCodeSemantic,
          onChanged: _handleCodeChanged,
          enabled: !_otpLocked && !_isLoading,
          errorText: inlineOtpError,
        ),
      ),
      continueButton: Semantics(
        button: true,
        label: l10n.authOtpContinue,
        child: AppButton.primary(
          label: l10n.authOtpContinue,
          enabled: !_isLoading && !_otpLocked,
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
