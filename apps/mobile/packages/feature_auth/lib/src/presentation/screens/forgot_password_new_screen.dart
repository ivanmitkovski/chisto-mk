import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/validation/password_strength.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/field_error_mapping.dart';
import 'package:chisto_infrastructure/shared/forms/form_validation_mixin.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/auth_text_field.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/password_strength_indicator.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_screen_header.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_shell.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/loading_overlay.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/password_reset_new_password_controller.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:feature_auth/src/presentation/widgets/auth_form_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordNewScreen extends ConsumerStatefulWidget {
  const ForgotPasswordNewScreen({
    super.key,
    required this.target,
    required this.code,
  });

  final PasswordResetTarget target;
  final String code;

  @override
  ConsumerState<ForgotPasswordNewScreen> createState() =>
      _ForgotPasswordNewScreenState();
}

class _ForgotPasswordNewScreenState
    extends ConsumerState<ForgotPasswordNewScreen>
    with FormValidationMixin {
  static const List<String> _fieldOrder = <String>[
    FormFieldIds.newPassword,
    FormFieldIds.confirmPassword,
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _confirmFieldKey = GlobalKey();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  PasswordStrength _passwordStrength = PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onInputChanged);
    _confirmController.addListener(_onInputChanged);
    registerFormField(
      FormFieldIds.newPassword,
      focusNode: _passwordFocus,
      fieldKey: _passwordFieldKey,
    );
    registerFormField(
      FormFieldIds.confirmPassword,
      focusNode: _confirmFocus,
      fieldKey: _confirmFieldKey,
    );
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
    if (hasActiveValidation) {
      _formKey.currentState?.validate();
    }
    ref.read(passwordResetNewPasswordControllerProvider.notifier).clearError();
    clearServerFieldErrors();
  }

  Map<String, String? Function()> _validators(AppLocalizations l10n) =>
      <String, String? Function()>{
        FormFieldIds.newPassword: () =>
            AuthValidators.password(l10n, _passwordController.text),
        FormFieldIds.confirmPassword: () => AuthValidators.confirmPassword(
          l10n,
          _passwordController.text.trim(),
        )(_confirmController.text),
      };

  Future<void> _handleReset() async {
    if (ref.read(passwordResetNewPasswordControllerProvider).isLoading) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    setState(() => submitAttempted = true);
    await WidgetsBinding.instance.endOfFrame;
    _formKey.currentState?.validate();
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
          .read(passwordResetNewPasswordControllerProvider.notifier)
          .confirm(
            target: widget.target,
            code: widget.code,
            newPassword: _passwordController.text.trim(),
          );
      if (!mounted) return;
      AppHaptics.success(context);
      AppNavigation.goForgotPasswordSuccess();
    } on AppError catch (e) {
      if (!mounted) return;
      final Map<String, String> fieldErrors = fieldErrorsFromAppError(e, l10n);
      if (fieldErrors.isNotEmpty) {
        setServerFieldErrors(fieldErrors);
        _formKey.currentState?.validate();
        await focusAndScrollToFirstInvalid(
          context,
          _fieldOrder,
          _validators(l10n),
        );
      }
      AppHaptics.warning(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(passwordResetNewPasswordControllerProvider);
    final bool isLoading = formState.isLoading;
    final String? apiError = formState.error != null
        ? authBannerMessageForError(
            l10n,
            formState.error!,
            displayedFieldIds: registeredFieldIds,
          )
        : null;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        AuthShell(
          header: AuthScreenHeader(
            showBackButton: true,
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                AppNavigation.goSignIn();
              }
            },
            title: l10n.authNewPasswordTitle,
            subtitle: l10n.authNewPasswordSubtitle,
          ),
          body: AuthFormScaffold(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg + keyboardInset,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (apiError != null) ...[
                    ApiErrorBanner(
                      message: apiError,
                      onDismiss: () => ref
                          .read(
                            passwordResetNewPasswordControllerProvider.notifier,
                          )
                          .clearError(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AuthTextField(
                    key: _passwordFieldKey,
                    label: l10n.authFieldNewPassword,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hintText: l10n.authFieldNewPasswordHint,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    validator: (String? v) => validateIfVisible(
                      FormFieldIds.newPassword,
                      () => AuthValidators.password(l10n, v),
                    ),
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const <String>[
                      AutofillHints.newPassword,
                    ],
                    onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                  ),
                  PasswordStrengthIndicator(
                    strength: _passwordStrength,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AuthTextField(
                    key: _confirmFieldKey,
                    label: l10n.authFieldConfirmPassword,
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    hintText: l10n.authFieldConfirmPasswordHint,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    validator: (String? v) => validateIfVisible(
                      FormFieldIds.confirmPassword,
                      () => AuthValidators.confirmPassword(
                        l10n,
                        _passwordController.text.trim(),
                      )(v),
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
                      enabled: !isLoading,
                      onPressed: isLoading ? null : _handleReset,
                    ),
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
