import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/features/auth/presentation/utils/auth_validators.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/validation/macedonian_phone_formatter.dart';
import 'package:chisto_mobile/core/validation/phone_normalizer.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/auth_shell.dart';
import 'package:chisto_mobile/shared/widgets/auth_text_field.dart';
import 'package:chisto_mobile/shared/widgets/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  State<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState
    extends State<ForgotPasswordRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '';
    _phoneController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onInputChanged);
    _phoneFocus.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {
      if (_apiError != null) _apiError = null;
    });
  }

  bool get _canSubmit =>
      _phoneController.text.trim().replaceAll(RegExp(r'\D'), '').length == 8;

  Future<void> _handleSendCode() async {
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
      final String phoneE164 = normalizeToE164(_phoneController.text);
      await ServiceLocator.instance.authRepository
          .requestPasswordReset(phoneE164);
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHaptics.success(context);
      Navigator.of(context).pushNamed(
        AppRoutes.forgotPasswordOtp,
        arguments: phoneE164,
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
              AppBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.authForgotPasswordTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authForgotPasswordSubtitle,
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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          label: l10n.authFieldPhoneNumber,
                          hintText: l10n.authFieldPhoneHint,
                          prefixFixedText: '+389',
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[
                            AutofillHints.telephoneNumber,
                          ],
                          validator: (String? v) =>
                              AuthValidators.macedonianPhone(l10n, v),
                          inputFormatters: const <TextInputFormatter>[
                            MacedonianPhoneFormatter(),
                          ],
                          onFieldSubmitted: (_) => _handleSendCode(),
                        ),
                        const SizedBox(height: AppSpacing.radius22),
                        Semantics(
                          button: true,
                          label: l10n.authForgotPasswordRequestSemantic,
                          child: PrimaryButton(
                            label: l10n.authForgotPasswordSendCode,
                            enabled: _canSubmit && !_isLoading,
                            onPressed: _isLoading ? null : _handleSendCode,
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
