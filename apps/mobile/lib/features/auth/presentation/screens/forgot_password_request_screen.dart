import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/auth_shell.dart';
import 'package:chisto_mobile/shared/widgets/auth_text_field.dart';
import 'package:chisto_mobile/shared/widgets/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/_macedonian_phone_formatter.dart';

class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  State<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState extends State<ForgotPasswordRequestScreen> {
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

  bool get _canSubmit => _phoneController.text.trim().replaceAll(RegExp(r'\D'), '').length == 8;

  String? _validateMacedonianPhone(String? value) {
    final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length != 8) return 'Enter an 8-digit phone number';
    return null;
  }

  Future<void> _handleSendCode() async {
    if (_isLoading) return;
    final FormState? formState = _formKey.currentState;
    setState(() => _hasSubmitted = true);
    if (formState == null || !formState.validate()) {
      AppHaptics.tap();
      return;
    }

    AppHaptics.light();
    setState(() => _isLoading = true);
    await Future<void>.delayed(AppMotion.slow);
    if (!mounted) return;

    setState(() => _isLoading = false);
    AppHaptics.success();

    final String digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final String formattedLocal = formatMacedonianLocalPhone(digits);
    final String displayNumber = '+389 $formattedLocal';

    Navigator.of(context).pushNamed(
      AppRoutes.forgotPasswordOtp,
      arguments: displayNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthShell(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: 'Go back',
                child: AppBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Reset password',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter your phone number and we\'ll send you a code to reset your password',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
              final bool keyboardVisible = keyboardInset > 0;

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
                          label: 'Phone Number',
                          hintText: '71 234 567',
                          prefixFixedText: '+389',
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[
                            AutofillHints.telephoneNumber,
                          ],
                          validator: _validateMacedonianPhone,
                          inputFormatters: const <TextInputFormatter>[
                            MacedonianPhoneFormatter(),
                          ],
                          onFieldSubmitted: (_) => _handleSendCode(),
                        ),
                        SizedBox(
                          height: keyboardVisible
                              ? AppSpacing.radius10
                              : AppSpacing.radius22,
                        ),
                        PrimaryButton(
                          label: 'Send reset code',
                          enabled: _canSubmit && !_isLoading,
                          onPressed: _isLoading ? null : _handleSendCode,
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
