import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/validation/input_validators.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/auth_shell.dart';
import 'package:chisto_mobile/shared/widgets/auth_text_field.dart';
import 'package:chisto_mobile/shared/widgets/brand_logo.dart';
import 'package:chisto_mobile/shared/widgets/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/_macedonian_phone_formatter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _hasSubmitted = false;
  bool _hasValidationError = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '';
    _fullNameController.addListener(_onInputChanged);
    _emailController.addListener(_onInputChanged);
    _phoneController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {
      if (_apiError != null) _apiError = null;
    });
  }

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _fullNameController.removeListener(_onInputChanged);
    _emailController.removeListener(_onInputChanged);
    _phoneController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isSubmitReady {
    return InputValidators.validateRequired(_fullNameController.text, 'Full name') == null &&
        InputValidators.validateEmail(_emailController.text) == null &&
        _validateMacedonianPhone(_phoneController.text) == null &&
        InputValidators.validatePassword(_passwordController.text) == null;
  }

  String? _validateMacedonianPhone(String? value) {
    final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Phone number is required';
    }
    if (digits.length != 8) {
      return 'Enter an 8-digit phone number';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    final FormState? currentState = _formKey.currentState;
    setState(() => _hasSubmitted = true);
    if (currentState == null) {
      setState(() => _hasValidationError = true);
      AppHaptics.tap();
      return;
    }
    final bool isValid = currentState.validate();
    if (!isValid) {
      setState(() => _hasValidationError = true);
      AppHaptics.tap();
      return;
    }
    setState(() => _hasValidationError = false);

    setState(() => _isLoading = true);
    await Future<void>.delayed(AppMotion.slow);
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    AppHaptics.light();
    final String localDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final String formattedLocal = formatMacedonianLocalPhone(localDigits);
    final String displayNumber = localDigits.isEmpty ? '' : '+389 $formattedLocal';

    Navigator.of(context).pushNamed(
      AppRoutes.otp,
      arguments: displayNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthShell(
          header: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandLogo(compact: true),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Sign up',
                style: AppTypography.authHeadline,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Welcome! Please enter your details',
                style: AppTypography.authSubtitle,
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.radius18),
                  child: AutofillGroup(
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
                            label: 'Full Name',
                            controller: _fullNameController,
                            focusNode: _fullNameFocus,
                            hintText: 'John Doe',
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const <String>[AutofillHints.name],
                            onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                            validator: (String? value) =>
                                InputValidators.validateRequired(value, 'Full name'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AuthTextField(
                            label: 'Email',
                            controller: _emailController,
                            focusNode: _emailFocus,
                            hintText: 'john@chisto.mk',
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const <String>[AutofillHints.email],
                            onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                            validator: InputValidators.validateEmail,
                            enableSuggestions: false,
                            autocorrect: false,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AuthTextField(
                            label: 'Phone Number',
                            hintText: '71 234 567',
                            prefixFixedText: '+389',
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[AutofillHints.telephoneNumber],
                            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            validator: _validateMacedonianPhone,
                            inputFormatters: const <TextInputFormatter>[MacedonianPhoneFormatter()],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AuthTextField(
                            label: 'Password',
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            hintText: 'Enter your password',
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: InputValidators.validatePassword,
                            autofillHints: const <String>[AutofillHints.newPassword],
                            enableSuggestions: false,
                            autocorrect: false,
                            onFieldSubmitted: (_) => _handleSignUp(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: const TextSpan(
                              text: 'By signing up you agree to our ',
                              style: AppTypography.authSubtitle,
                              children: [
                                TextSpan(
                                  text: 'terms and conditions',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AnimatedSize(
                            duration: AppMotion.fast,
                            curve: AppMotion.emphasized,
                            child: _hasValidationError
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Text(
                                      'Please check the highlighted fields above.',
                                      style: AppTypography.cardSubtitle.copyWith(color: AppColors.error),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          PrimaryButton(
                            label: 'Sign Up',
                            enabled: _isSubmitReady && !_isLoading,
                            onPressed: _isLoading ? null : _handleSignUp,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Center(
                            child: Semantics(
                              button: true,
                              label: 'Sign in',
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.of(context).pushReplacementNamed(AppRoutes.signIn),
                                child: RichText(
                                text: const TextSpan(
                                  text: 'Already have an account? ',
                                  style: AppTypography.authSubtitle,
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
              );
            },
          ),
        ),
        LoadingOverlay(visible: _isLoading),
      ],
    );
  }
}
