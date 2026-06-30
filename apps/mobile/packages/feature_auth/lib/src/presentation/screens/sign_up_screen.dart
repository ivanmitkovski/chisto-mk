import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/validation/macedonian_phone_formatter.dart';
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
import 'package:feature_auth/src/application/sign_up_controller.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:feature_auth/src/presentation/widgets/auth_form_scaffold.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin, FormValidationMixin {
  static const List<String> _fieldOrder = <String>[
    FormFieldIds.fullName,
    FormFieldIds.email,
    FormFieldIds.phone,
    FormFieldIds.password,
    FormFieldIds.terms,
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _fullNameFieldKey = GlobalKey();
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _termsAccepted = false;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '';
    _fullNameController.addListener(_onInputChanged);
    _emailController.addListener(_onInputChanged);
    _phoneController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
    _fullNameFocus.addListener(_scrollToFocusedField);
    _emailFocus.addListener(_scrollToFocusedField);
    _phoneFocus.addListener(_scrollToFocusedField);
    _passwordFocus.addListener(_scrollToFocusedField);
    registerFormField(
      FormFieldIds.fullName,
      focusNode: _fullNameFocus,
      fieldKey: _fullNameFieldKey,
    );
    registerFormField(
      FormFieldIds.email,
      focusNode: _emailFocus,
      fieldKey: _emailFieldKey,
    );
    registerFormField(
      FormFieldIds.phone,
      focusNode: _phoneFocus,
      fieldKey: _phoneFieldKey,
    );
    registerFormField(
      FormFieldIds.password,
      focusNode: _passwordFocus,
      fieldKey: _passwordFieldKey,
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.emphasized,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _entranceController.value = 1.0;
      } else {
        _entranceController.forward();
      }
    });
  }

  void _scrollToFocusedField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final BuildContext? ctx = _fullNameFocus.hasFocus
            ? _fullNameFieldKey.currentContext
            : _emailFocus.hasFocus
            ? _emailFieldKey.currentContext
            : _phoneFocus.hasFocus
            ? _phoneFieldKey.currentContext
            : _passwordFocus.hasFocus
            ? _passwordFieldKey.currentContext
            : null;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.2,
            duration: AppMotion.standard,
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {
      _passwordStrength = computePasswordStrength(_passwordController.text);
    });
    if (hasActiveValidation) {
      _formKey.currentState?.validate();
    }
    ref.read(signUpControllerProvider.notifier).clearError();
    clearServerFieldErrors();
  }

  Map<String, String? Function()> _validators(AppLocalizations l10n) =>
      <String, String? Function()>{
        FormFieldIds.fullName: () =>
            AuthValidators.fullName(l10n, _fullNameController.text),
        FormFieldIds.email: () =>
            AuthValidators.email(l10n, _emailController.text),
        FormFieldIds.phone: () =>
            AuthValidators.macedonianPhone(l10n, _phoneController.text),
        FormFieldIds.password: () =>
            AuthValidators.password(l10n, _passwordController.text),
        FormFieldIds.terms: () =>
            AuthValidators.termsAccepted(l10n, _termsAccepted),
      };

  Future<void> _handleSignUp() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ref.read(signUpControllerProvider.notifier).clearError();
    clearServerFieldErrors();
    setState(() => submitAttempted = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
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
      final String fullName = _fullNameController.text.trim();
      final List<String> parts = fullName.split(RegExp(r'\s+'));
      final String firstName = parts.first;
      final String lastName = parts.length > 1
          ? parts.sublist(1).join(' ')
          : '';
      final String phoneE164 = normalizeToE164(_phoneController.text);

      await ref
          .read(signUpControllerProvider.notifier)
          .signUp(
            firstName: firstName,
            lastName: lastName,
            email: _emailController.text.trim(),
            phoneNumberE164: phoneE164,
            password: _passwordController.text,
          );
      if (!mounted) return;
      AppHaptics.success(context);
      AppNavigation.goOtpPhone(phoneE164);
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
  void dispose() {
    _fullNameFocus.removeListener(_scrollToFocusedField);
    _emailFocus.removeListener(_scrollToFocusedField);
    _phoneFocus.removeListener(_scrollToFocusedField);
    _passwordFocus.removeListener(_scrollToFocusedField);
    _fullNameController.removeListener(_onInputChanged);
    _emailController.removeListener(_onInputChanged);
    _phoneController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final formState = ref.watch(signUpControllerProvider);
    final bool isLoading = formState.isLoading;
    final String? apiError = formState.error != null
        ? authBannerMessageForError(
            l10n,
            formState.error!,
            displayedFieldIds: registeredFieldIds,
          )
        : null;
    final String termsUrl = ref.watch(appConfigProvider).termsUrl;

    return Stack(
      children: [
        AuthShell(
          header: FadeTransition(
            opacity: _entranceAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(_entranceAnimation),
              child: AuthScreenHeader(
                showLogo: true,
                title: l10n.authSignUpTitle,
                subtitle: l10n.authSignUpSubtitle,
              ),
            ),
          ),
          body: AuthFormScaffold(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg + keyboardInset,
            ),
            child: FadeTransition(
              opacity: _entranceAnimation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _entranceController,
                        curve: const Interval(0.15, 1, curve: Curves.easeOut),
                      ),
                    ),
                child: AutofillGroup(
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
                                .read(signUpControllerProvider.notifier)
                                .clearError(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AuthTextField(
                          key: _fullNameFieldKey,
                          label: l10n.authFieldFullName,
                          controller: _fullNameController,
                          focusNode: _fullNameFocus,
                          hintText: l10n.authFieldFullNameHint,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[AutofillHints.name],
                          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                          validator: (String? v) => validateIfVisible(
                            FormFieldIds.fullName,
                            () => AuthValidators.fullName(l10n, v),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AuthTextField(
                          key: _emailFieldKey,
                          label: l10n.authFieldEmail,
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hintText: l10n.authFieldEmailHint,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[AutofillHints.email],
                          onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                          validator: (String? value) => validateIfVisible(
                            FormFieldIds.email,
                            () => AuthValidators.email(l10n, value),
                          ),
                          enableSuggestions: false,
                          autocorrect: false,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AuthTextField(
                          key: _phoneFieldKey,
                          label: l10n.authFieldPhoneNumber,
                          hintText: l10n.authFieldPhoneHint,
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
                          validator: (String? value) => validateIfVisible(
                            FormFieldIds.phone,
                            () => AuthValidators.macedonianPhone(l10n, value),
                          ),
                          inputFormatters: const <TextInputFormatter>[
                            MacedonianPhoneFormatter(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AuthTextField(
                          key: _passwordFieldKey,
                          label: l10n.authFieldPassword,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hintText: l10n.authFieldPasswordHint,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (String? value) => validateIfVisible(
                            FormFieldIds.password,
                            () => AuthValidators.password(l10n, value),
                          ),
                          enableSuggestions: false,
                          autocorrect: false,
                          scrollPadding: EdgeInsets.only(
                            bottom: keyboardInset + 100,
                          ),
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
                          onFieldSubmitted: (_) => _handleSignUp(),
                        ),
                        PasswordStrengthIndicator(strength: _passwordStrength),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.authPasswordRequirementsHint,
                          style: AppTypography.cardSubtitle(textTheme),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Semantics(
                          checked: _termsAccepted,
                          child: Material(
                            color: AppColors.transparent,
                            child: CheckboxListTile(
                              value: _termsAccepted,
                              onChanged: (bool? value) {
                                setState(() => _termsAccepted = value ?? false);
                                markFieldTouched(FormFieldIds.terms);
                                if (hasActiveValidation) {
                                  _formKey.currentState?.validate();
                                }
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: RichText(
                                text: TextSpan(
                                  style: AppTypography.authSubtitle(textTheme),
                                  children: <TextSpan>[
                                    TextSpan(text: l10n.authTermsPrefix),
                                    TextSpan(
                                      text: l10n.authTermsLink,
                                      style:
                                          AppTypography.authTextLinkUnderline(
                                            textTheme,
                                          ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          final Uri uri = Uri.parse(termsUrl);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (shouldShowFieldError(FormFieldIds.terms))
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              AuthValidators.termsAccepted(
                                    l10n,
                                    _termsAccepted,
                                  ) ??
                                  '',
                              style: AppTypography.cardSubtitle(
                                textTheme,
                              ).copyWith(color: AppColors.error),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        Semantics(
                          button: true,
                          label: l10n.authSignUpCta,
                          child: AppButton.primary(
                            label: l10n.authSignUpCta,
                            enabled: !isLoading,
                            onPressed: isLoading ? null : _handleSignUp,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Center(
                          child: Semantics(
                            button: true,
                            label:
                                '${l10n.authSignInPrompt}${l10n.authSignInLink}',
                            child: GestureDetector(
                              onTap: AppNavigation.goSignIn,
                              child: RichText(
                                text: TextSpan(
                                  text: l10n.authSignInPrompt,
                                  style: AppTypography.authSubtitle(textTheme),
                                  children: [
                                    TextSpan(
                                      text: l10n.authSignInLink,
                                      style: AppTypography.authTextLink(
                                        textTheme,
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
            ),
          ),
        ),
        LoadingOverlay(visible: isLoading),
      ],
    );
  }
}
