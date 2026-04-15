import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/features/auth/presentation/utils/auth_validators.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/validation/password_strength.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/password_strength_indicator.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/auth_shell.dart';
import 'package:chisto_mobile/shared/widgets/auth_text_field.dart';
import 'package:chisto_mobile/shared/widgets/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class ForgotPasswordNewScreen extends StatefulWidget {
  const ForgotPasswordNewScreen({
    super.key,
    required this.phoneNumberE164,
    required this.code,
  });

  final String phoneNumberE164;
  final String code;

  @override
  State<ForgotPasswordNewScreen> createState() =>
      _ForgotPasswordNewScreenState();
}

class _ForgotPasswordNewScreenState extends State<ForgotPasswordNewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _apiError;
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
      if (_apiError != null) _apiError = null;
    });
  }

  bool get _canSubmit {
    return _passwordController.text.trim().isNotEmpty &&
        _confirmController.text.trim().isNotEmpty;
  }

  Future<void> _handleReset() async {
    if (_isLoading) return;
    final FormState? formState = _formKey.currentState;
    setState(() => _hasSubmitted = true);
    if (formState == null || !formState.validate()) {
      AppHaptics.tap(context);
      return;
    }

    AppHaptics.light(context);
    setState(() => _isLoading = true);
    setState(() => _apiError = null);

    try {
      await ServiceLocator.instance.authRepository.confirmPasswordReset(
        phoneNumberE164: widget.phoneNumberE164,
        code: widget.code,
        newPassword: _passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHaptics.success(context);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.forgotPasswordSuccess,
        (Route<dynamic> route) => route.settings.name == AppRoutes.signIn,
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      setState(
        () => _apiError = messageForAuthError(AppLocalizations.of(context)!, e),
      );
      AppHaptics.warning(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        AuthShell(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.authNewPasswordTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authNewPasswordSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double keyboardInset =
                  MediaQuery.viewInsetsOf(context).bottom;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg + keyboardInset,
                ),
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
                        if (_apiError != null) ...[
                          ApiErrorBanner(
                            message: _apiError!,
                            onDismiss: () => setState(() => _apiError = null),
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
                        PasswordStrengthIndicator(strength: _passwordStrength),
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
                          child: PrimaryButton(
                            label: l10n.authResetPasswordCta,
                            enabled: _canSubmit && !_isLoading,
                            onPressed: _isLoading ? null : _handleReset,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        LoadingOverlay(visible: _isLoading),
      ],
    );
  }
}
