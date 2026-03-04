import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/validation/input_validators.dart';
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
    if (!mounted) {
      return;
    }
    setState(() {});
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
      HapticFeedback.selectionClick();
      return;
    }
    final bool isValid = currentState.validate();
    if (!isValid) {
      setState(() => _hasValidationError = true);
      HapticFeedback.selectionClick();
      return;
    }
    setState(() => _hasValidationError = false);

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

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
              BrandLogo(),
              SizedBox(height: 18),
              Text(
                'Sign up',
                style: AppTypography.authHeadline,
              ),
              SizedBox(height: 10),
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
                  20,
                  22,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 18),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _hasSubmitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 18),
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
                          const SizedBox(height: 18),
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
                          const SizedBox(height: 18),
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
                          const SizedBox(height: 16),
                          RichText(
                            text: const TextSpan(
                              text: 'By signing up you agree to our ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
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
                          const SizedBox(height: 20),
                          if (_hasValidationError) ...<Widget>[
                            const Text(
                              'Please check the highlighted fields above.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          PrimaryButton(
                            label: 'Sign Up',
                            enabled: _isSubmitReady && !_isLoading,
                            onPressed: _isLoading ? null : _handleSignUp,
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushReplacementNamed(AppRoutes.signIn),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
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
