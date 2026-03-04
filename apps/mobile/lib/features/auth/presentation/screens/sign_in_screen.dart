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

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  bool _hasValidationError = false;

  @override
  void initState() {
    super.initState();
    // Always start with an empty phone field; the example lives only in the hint.
    _phoneController.text = '';
    _phoneController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  bool get _canSubmit {
    return _phoneController.text.trim().isNotEmpty && _passwordController.text.trim().isNotEmpty;
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

  Future<void> _handleSignIn() async {
    if (_isLoading) {
      return;
    }
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

    HapticFeedback.lightImpact();
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
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              BrandLogo(),
              SizedBox(height: 18),
              Text(
                'Sign in',
                style: AppTypography.authHeadline,
              ),
              SizedBox(height: 10),
              Text(
                'Welcome back! Please enter your details',
                style: AppTypography.authSubtitle,
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
                  22,
                  20,
                  22,
                  24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      autovalidateMode:
                          _hasSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
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
                            keyboardType: TextInputType.visiblePassword,
                            validator: InputValidators.validatePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[AutofillHints.password],
                            enableSuggestions: false,
                            autocorrect: false,
                            onFieldSubmitted: (_) => _handleSignIn(),
                          ),
                          const SizedBox(height: 14),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: _rememberMe ? AppColors.appBackground : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _rememberMe = !_rememberMe);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          curve: Curves.easeOutCubic,
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                _rememberMe ? AppColors.primary : Colors.transparent,
                                            border: Border.all(
                                              color: _rememberMe
                                                  ? AppColors.primary
                                                  : AppColors.inputBorder,
                                            ),
                                          ),
                                          child: _rememberMe
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 160),
                                          curve: Curves.easeOutCubic,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: _rememberMe
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: _rememberMe
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                          ),
                                          child: const Text('Remember me'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    minimumSize: const Size(44, 36),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_hasValidationError) ...<Widget>[
                            const SizedBox(height: 2),
                            const Text(
                              'Please check your phone number and password.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          PrimaryButton(
                            label: 'Sign In',
                            enabled: _canSubmit && !_isLoading,
                            onPressed: _isLoading ? null : _handleSignIn,
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: keyboardVisible
                                ? const SizedBox(height: 10)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 22),
                                    child: Center(
                                      child: Semantics(
                                        button: true,
                                        label: 'Create account',
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            Navigator.of(context)
                                                .pushNamed(AppRoutes.signUp);
                                          },
                                          child: RichText(
                                            text: const TextSpan(
                                              text: 'Don’t have an account? ',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 15.5,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'Sign Up',
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
