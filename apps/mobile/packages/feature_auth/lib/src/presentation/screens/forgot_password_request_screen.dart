import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/validation/macedonian_phone_formatter.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/auth_text_field.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_screen_header.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_shell.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/loading_overlay.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/password_reset_request_controller.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:feature_auth/src/presentation/widgets/auth_form_scaffold.dart';
import 'package:feature_auth/src/presentation/widgets/auth_secondary_action_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordRequestScreen extends ConsumerStatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  ConsumerState<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState
    extends ConsumerState<ForgotPasswordRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  bool _useEmail = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onInputChanged);
    _emailController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onInputChanged);
    _emailController.removeListener(_onInputChanged);
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {});
    ref.read(passwordResetRequestControllerProvider.notifier).clearError();
  }

  void _toggleResetChannel() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _useEmail = !_useEmail;
    });
    ref.read(passwordResetRequestControllerProvider.notifier).clearError();
    _formKey.currentState?.reset();
  }

  Future<void> _handleSendCode() async {
    final bool isLoading = ref
        .read(passwordResetRequestControllerProvider)
        .isLoading;
    if (isLoading) return;
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      AppHaptics.warning(context);
      return;
    }

    try {
      if (_useEmail) {
        final String email = _emailController.text.trim();
        await ref
            .read(passwordResetRequestControllerProvider.notifier)
            .requestByEmail(email);
        if (!mounted) return;
        AppHaptics.success(context);
        await AppNavigation.pushForgotPasswordOtp(
          PasswordResetTarget(
            channel: PasswordResetChannel.email,
            value: email,
          ),
        );
        return;
      }

      final String phoneE164 = normalizeToE164(_phoneController.text);
      await ref
          .read(passwordResetRequestControllerProvider.notifier)
          .requestByPhone(phoneE164);
      if (!mounted) return;
      AppHaptics.success(context);
      await AppNavigation.pushForgotPasswordOtp(
        PasswordResetTarget(
          channel: PasswordResetChannel.sms,
          value: phoneE164,
        ),
      );
    } on AppError {
      if (!mounted) return;
      AppHaptics.warning(context);
    }
  }

  Widget _buildInputField(AppLocalizations l10n) {
    if (_useEmail) {
      return AuthTextField(
        key: const ValueKey<String>('email'),
        controller: _emailController,
        focusNode: _emailFocus,
        label: l10n.authForgotPasswordEmailField,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        validator: (String? v) => AuthValidators.email(l10n, v),
        onFieldSubmitted: (_) => _handleSendCode(),
      );
    }
    return AuthTextField(
      key: const ValueKey<String>('phone'),
      controller: _phoneController,
      focusNode: _phoneFocus,
      label: l10n.authFieldPhone,
      prefixFixedText: '+389 ',
      inputFormatters: const <TextInputFormatter>[MacedonianPhoneFormatter()],
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      validator: (String? v) => AuthValidators.macedonianPhone(l10n, v),
      onFieldSubmitted: (_) => _handleSendCode(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(passwordResetRequestControllerProvider);
    final bool isLoading = formState.isLoading;
    final String? apiError = formState.error != null
        ? messageForAuthError(l10n, formState.error!)
        : null;
    final bool canSubmit = _useEmail
        ? AuthValidators.email(l10n, _emailController.text) == null
        : _phoneController.text.trim().replaceAll(RegExp(r'\D'), '').length ==
              8;
    return Stack(
      children: <Widget>[
        AuthShell(
          header: AuthScreenHeader(
            showBackButton: true,
            title: l10n.authForgotPasswordTitle,
            subtitle: _useEmail
                ? l10n.authForgotPasswordEmailSubtitle
                : l10n.authForgotPasswordSubtitle,
          ),
          body: AuthFormScaffold(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildInputField(l10n),
                  ),
                  if (apiError != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    ApiErrorBanner(
                      message: apiError,
                      onDismiss: () => ref
                          .read(passwordResetRequestControllerProvider.notifier)
                          .clearError(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: l10n.authForgotPasswordSendCode,
                    enabled: canSubmit && !isLoading,
                    onPressed: isLoading ? null : _handleSendCode,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthSecondaryActionLink(
                    semanticsKey: const Key(
                      'auth_forgot_password_alternate_method',
                    ),
                    prompt: l10n.authForgotPasswordTryAnotherWay,
                    linkLabel: _useEmail
                        ? l10n.authResetViaSms
                        : l10n.authResetViaEmail,
                    onTap: _toggleResetChannel,
                  ),
                ],
              ),
            ),
          ),
        ),
        LoadingOverlay(visible: isLoading),
      ],
    );
  }
}
