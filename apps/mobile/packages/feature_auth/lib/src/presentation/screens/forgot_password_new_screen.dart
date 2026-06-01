import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/validation/password_strength.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/auth_text_field.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/password_strength_indicator.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_screen_header.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_shell.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/loading_overlay.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/password_reset_new_password_controller.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:feature_auth/src/presentation/widgets/auth_form_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordNewScreen extends ConsumerStatefulWidget {
  const ForgotPasswordNewScreen({
    super.key,
    this.phoneNumberE164 = '',
    this.code = '',
    this.emailResetToken,
  });

  final String phoneNumberE164;
  final String code;
  final String? emailResetToken;

  bool get _isEmailReset =>
      emailResetToken != null && emailResetToken!.trim().isNotEmpty;

  @override
  ConsumerState<ForgotPasswordNewScreen> createState() =>
      _ForgotPasswordNewScreenState();
}

class _ForgotPasswordNewScreenState
    extends ConsumerState<ForgotPasswordNewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  bool _hasSubmitted = false;
  PasswordStrength _passwordStrength = PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onInputChanged);
    _confirmController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onInputChanged);
    _confirmController.removeListener(_onInputChanged);
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {
      _passwordStrength = computePasswordStrength(_passwordController.text);
    });
    ref.read(passwordResetNewPasswordControllerProvider.notifier).clearError();
  }

  bool get _canSubmit {
    return _passwordController.text.trim().isNotEmpty &&
        _confirmController.text.trim().isNotEmpty;
  }

  Future<void> _handleReset() async {
    if (ref.read(passwordResetNewPasswordControllerProvider).isLoading) return;
    final FormState? formState = _formKey.currentState;
    setState(() => _hasSubmitted = true);
    if (formState == null || !formState.validate()) {
      AppHaptics.warning(context);
      return;
    }

    try {
      if (widget._isEmailReset) {
        await ref
            .read(passwordResetNewPasswordControllerProvider.notifier)
            .confirmByEmail(
              token: widget.emailResetToken!.trim(),
              newPassword: _passwordController.text.trim(),
            );
      } else {
        await ref
            .read(passwordResetNewPasswordControllerProvider.notifier)
            .confirmByPhone(
              phoneNumberE164: widget.phoneNumberE164,
              code: widget.code,
              newPassword: _passwordController.text.trim(),
            );
      }
      if (!mounted) return;
      AppHaptics.success(context);
      AppNavigation.goForgotPasswordSuccess();
    } on AppError {
      if (!mounted) return;
      AppHaptics.warning(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(passwordResetNewPasswordControllerProvider);
    final bool isLoading = formState.isLoading;
    final String? apiError = formState.error != null
        ? messageForAuthError(l10n, formState.error!)
        : null;

    return Stack(
      children: [
        AuthShell(
          header: AuthScreenHeader(
            showBackButton: true,
            title: l10n.authNewPasswordTitle,
            subtitle: l10n.authNewPasswordSubtitle,
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double keyboardInset = MediaQuery.viewInsetsOf(
                context,
              ).bottom;

              return AuthFormScaffold(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg + keyboardInset,
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSpacing.xl,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _hasSubmitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (apiError != null) ...[
                            ApiErrorBanner(
                              message: apiError,
                              onDismiss: () => ref
                                  .read(
                                    passwordResetNewPasswordControllerProvider
                                        .notifier,
                                  )
                                  .clearError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          AuthTextField(
                            label: l10n.authFieldNewPassword,
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            hintText: l10n.authFieldNewPasswordHint,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.next,
                            validator: (String? v) =>
                                AuthValidators.password(l10n, v),
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const <String>[
                              AutofillHints.newPassword,
                            ],
                            onFieldSubmitted: (_) =>
                                _confirmFocus.requestFocus(),
                          ),
                          PasswordStrengthIndicator(
                            strength: _passwordStrength,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AuthTextField(
                            label: l10n.authFieldConfirmPassword,
                            controller: _confirmController,
                            focusNode: _confirmFocus,
                            hintText: l10n.authFieldConfirmPasswordHint,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            validator: AuthValidators.confirmPassword(
                              l10n,
                              _passwordController.text.trim(),
                            ),
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const <String>[
                              AutofillHints.newPassword,
                            ],
                            onFieldSubmitted: (_) => _handleReset(),
                          ),
                          const SizedBox(height: AppSpacing.radius22),
                          Semantics(
                            button: true,
                            label: l10n.authResetPasswordCta,
                            child: AppButton.primary(
                              label: l10n.authResetPasswordCta,
                              enabled: _canSubmit && !isLoading,
                              onPressed: isLoading ? null : _handleReset,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        LoadingOverlay(visible: isLoading),
      ],
    );
  }
}
