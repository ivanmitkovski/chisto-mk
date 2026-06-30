import 'dart:async';

import 'package:chisto_infrastructure/core/assets/app_assets.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/field_error_mapping.dart';
import 'package:chisto_infrastructure/shared/forms/form_validation_mixin.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/loading_overlay.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/registration_otp_controller.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/constants/auth_otp_constants.dart';
import 'package:feature_auth/src/presentation/eula_acceptance_flow.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:feature_auth/src/presentation/utils/otp_focus_helper.dart';
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
    this.rememberMe = true,
  });

  @visibleForTesting
  static bool disableResendTimerForTests = false;

  final String phoneNumber;

  /// When `true`, calls `/auth/otp/send` once on open (e.g. unverified sign-in).
  final bool requestOtpOnOpen;

  /// Whether verified session tokens persist across app restarts.
  final bool rememberMe;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with FormValidationMixin {
  static const List<String> _fieldOrder = <String>[FormFieldIds.otp];

  final GlobalKey _otpFieldKey = GlobalKey();
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
      if (!OtpScreen.disableResendTimerForTests) {
        unawaited(ensureOtpKeyboardVisible(_codeFocusNode));
      }
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
    if (OtpScreen.disableResendTimerForTests) {
      return;
    }
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
    ref.read(registrationOtpControllerProvider.notifier).clearError();
    clearServerFieldErrors();
    if (value.length == kAuthOtpLength) {
      AppHaptics.tap(context);
    }
    setState(() {});

    if (_isComplete && !_isLoading && !_otpLocked) {
      unawaited(_onContinue());
    }
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

    try {
      await ref
          .read(registrationOtpControllerProvider.notifier)
          .verifyOtp(
            widget.phoneNumber,
            _codeController.text.trim(),
            rememberMe: widget.rememberMe,
          );
      if (!mounted) return;
      AppHaptics.success(context);
      final bool accepted = await ensureCommunityGuidelinesAccepted(
        context,
        ref,
      );
      if (!accepted || !mounted) return;
      AppNavigation.goLocation();
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
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) {
      return;
    }
    _codeController.clear();
    unawaited(ensureOtpKeyboardVisible(_codeFocusNode));
    setState(() => _hasResentOnce = true);
    ref.read(registrationOtpControllerProvider.notifier).resetAttempts();
    clearServerFieldErrors();
    _startResendCountdown();
    await _requestOtp();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final RegistrationOtpState otpState = _otpState;
    final String? inlineOtpError = _otpInlineError(l10n);
    final String? apiError = _otpLocked
        ? l10n.authErrorOtpMaxAttempts
        : otpState.error != null
        ? authBannerMessageForError(
            l10n,
            otpState.error!,
            displayedFieldIds: registeredFieldIds,
          )
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
