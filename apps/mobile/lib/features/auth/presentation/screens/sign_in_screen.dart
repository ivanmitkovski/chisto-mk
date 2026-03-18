import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/core/validation/phone_normalizer.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/validation/input_validators.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/auth_shell.dart';
import 'package:chisto_mobile/shared/widgets/auth_text_field.dart';
import 'package:chisto_mobile/shared/widgets/brand_logo.dart';
import 'package:chisto_mobile/shared/widgets/loading_overlay.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/core/validation/macedonian_phone_formatter.dart';

const String _keyRememberMe = 'chisto_remember_me';
const String _keyLastSignInPhone = 'chisto_last_signin_phone';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  bool _hasValidationError = false;
  String? _apiError;
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '';
    _phoneController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.emphasized,
    );
    _entranceController.forward();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    if (!ServiceLocator.instance.isInitialized) return;
    final prefs = ServiceLocator.instance.preferences;
    final bool rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    final String? lastPhone = prefs.getString(_keyLastSignInPhone);
    if (!mounted) return;
    setState(() {
      _rememberMe = rememberMe;
      if (rememberMe && lastPhone != null && lastPhone.isNotEmpty) {
        // National part only: field has prefixFixedText '+389', so avoid "+389 +389 ...".
        _phoneController.text = formatPhoneNationalPart(lastPhone);
      }
    });
  }

  Future<void> _saveRememberMe({required String phoneE164, required bool remember}) async {
    if (!ServiceLocator.instance.isInitialized) return;
    final prefs = ServiceLocator.instance.preferences;
    await prefs.setBool(_keyRememberMe, remember);
    if (remember) {
      await prefs.setString(_keyLastSignInPhone, phoneE164);
    } else {
      await prefs.remove(_keyLastSignInPhone);
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _scrollController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {
      if (_apiError != null) _apiError = null;
    });
  }


  bool get _canSubmit =>
      _phoneController.text.trim().replaceAll(RegExp(r'\D'), '').length == 8 &&
      _passwordController.text.trim().isNotEmpty;

  String? _validateMacedonianPhone(String? value) {
    final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length != 8) return 'Enter an 8-digit phone number';
    return null;
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    final FormState? formState = _formKey.currentState;
    setState(() => _hasSubmitted = true);
    if (formState == null || !formState.validate()) {
      setState(() => _hasValidationError = true);
      AppHaptics.warning();
      return;
    }
    setState(() => _hasValidationError = false);
    AppHaptics.light();
    setState(() {
      _isLoading = true;
      _apiError = null;
    });

    try {
      final String phoneE164 = normalizeToE164(_phoneController.text);
      await ServiceLocator.instance.authRepository.signIn(
        phoneNumber: phoneE164,
        password: _passwordController.text,
      );
      if (!mounted) return;
      await _saveRememberMe(phoneE164: phoneE164, remember: _rememberMe);
      if (!mounted) return;
      AppHaptics.success();
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (Route<dynamic> route) => false,
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _apiError = messageForAuthError(e));
      AppHaptics.warning();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    AppHaptics.tap();
    Navigator.of(context).pushNamed(AppRoutes.forgotPasswordRequest);
  }

  void _handleSignUp() {
    AppHaptics.tap();
    Navigator.of(context).pushNamed(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: <Widget>[
        AuthShell(
          header: FadeTransition(
            opacity: _entranceAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(_entranceAnimation),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const BrandLogo(compact: true),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sign in',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome back. Enter your details to continue.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl + keyboardInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.xl,
                  ),
                  child: IntrinsicHeight(
                    child: FadeTransition(
                      opacity: _entranceAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _entranceController,
                          curve: const Interval(0.15, 1, curve: Curves.easeOut),
                        )),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _hasSubmitted
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (_apiError != null) ...[
                                  ApiErrorBanner(
                                    message: _apiError!,
                                    onDismiss: () {
                                      setState(() => _apiError = null);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                AuthTextField(
                                  label: 'Phone number',
                                  hintText: '70 123 456',
                                  prefixFixedText: '+389',
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const <String>[
                                    AutofillHints.telephoneNumber,
                                  ],
                                  onFieldSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                  validator: _validateMacedonianPhone,
                                  inputFormatters: const <TextInputFormatter>[
                                    MacedonianPhoneFormatter(),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AuthTextField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  hintText: 'Enter your password',
                                  obscureText: true,
                                  keyboardType: TextInputType.visiblePassword,
                                  validator: InputValidators.validatePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const <String>[
                                    AutofillHints.password,
                                  ],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  onFieldSubmitted: (_) => _handleSignIn(),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _RememberMeRow(
                                  value: _rememberMe,
                                  onChanged: (bool v) {
                                    setState(() => _rememberMe = v);
                                  },
                                  onForgotPassword: _handleForgotPassword,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AnimatedSwitcher(
                                  duration: AppMotion.fast,
                                  switchInCurve: AppMotion.emphasized,
                                  switchOutCurve: AppMotion.emphasized,
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> animation,
                                  ) =>
                                      SizeTransition(
                                    sizeFactor: animation,
                                    axisAlignment: -1,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                                  child: _hasValidationError
                                      ? Padding(
                                          key: const ValueKey<bool>(true),
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.sm,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              Icon(
                                                CupertinoIcons.exclamationmark_circle_fill,
                                                size: 18,
                                                color: AppColors.accentDanger,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.xs,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Please check your phone number and password.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppColors.accentDanger,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(
                                          key: ValueKey<bool>(false),
                                        ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'Sign in',
                                  child: PrimaryButton(
                                    label: 'Sign in',
                                    enabled: _canSubmit && !_isLoading,
                                    onPressed: _isLoading ? null : _handleSignIn,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.radius22),
                                Center(
                                    child: Semantics(
                                      button: true,
                                      label: 'Create account',
                                      child: GestureDetector(
                                        onTap: _handleSignUp,
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.sm,
                                          ),
                                          child: RichText(
                                            text: TextSpan(
                                              text: 'Don\'t have an account? ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: AppColors.textMuted,
                                                  ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: 'Sign up',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.primaryDark,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
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

class _RememberMeRow extends StatelessWidget {
  const _RememberMeRow({
    required this.value,
    required this.onChanged,
    required this.onForgotPassword,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radius14),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              button: true,
              label: 'Remember me',
              child: InkWell(
                onTap: () => onChanged(!value),
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CupertinoSwitch(
                        value: value,
                        onChanged: onChanged,
                        activeTrackColor: AppColors.primaryDark,
                        inactiveTrackColor: AppColors.divider,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Remember me',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                          color: value
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Forgot password?',
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                onPressed: onForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
