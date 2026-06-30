import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:chisto_infrastructure/core/deep_links/deep_link_router.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_language_picker.dart';
import 'package:chisto_infrastructure/core/l10n/app_locale_resolution.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/validation/macedonian_phone_formatter.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/field_error_mapping.dart';
import 'package:chisto_infrastructure/shared/forms/form_validation_mixin.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/sign_in_controller.dart';
import 'package:feature_auth/src/data/user_home_location_store.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/eula_acceptance_flow.dart';
import 'package:feature_auth/src/presentation/utils/auth_guard_ui.dart';
import 'package:feature_auth/src/presentation/utils/auth_validators.dart';
import 'package:feature_auth/src/presentation/widgets/auth_form_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin, FormValidationMixin {
  static const List<String> _fieldOrder = <String>[
    FormFieldIds.phone,
    FormFieldIds.password,
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _phonePrefilled = false;
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '';
    _phoneController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
    _phoneFocus.addListener(_scrollToFocusedField);
    _passwordFocus.addListener(_scrollToFocusedField);
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
        final BuildContext? ctx = _phoneFocus.hasFocus
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

  @override
  void dispose() {
    _phoneController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _phoneFocus.removeListener(_scrollToFocusedField);
    _passwordFocus.removeListener(_scrollToFocusedField);
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
    if (hasActiveValidation) {
      _formKey.currentState?.validate();
    }
    ref.read(signInControllerProvider.notifier).clearError();
    clearServerFieldErrors();
    setState(() {});
  }

  Map<String, String? Function()> _validators(AppLocalizations l10n) =>
      <String, String? Function()>{
        FormFieldIds.phone: () =>
            AuthValidators.macedonianPhone(l10n, _phoneController.text),
        FormFieldIds.password: () =>
            AuthValidators.loginPassword(l10n, _passwordController.text),
      };

  Future<void> _handleSignIn() async {
    if (ref.read(signInControllerProvider).isLoading) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
    final String phoneE164 = normalizeToE164(_phoneController.text);
    try {
      await ref
          .read(signInControllerProvider.notifier)
          .signIn(
            phoneNumberE164: phoneE164,
            password: _passwordController.text,
          );
      if (!mounted) return;
      AppHaptics.success(context);
      final bool accepted = await ensureCommunityGuidelinesAccepted(
        context,
        ref,
      );
      if (!accepted || !mounted) return;
      final UserHomeLocationStore homeStore = UserHomeLocationStore(
        ref.read(preferencesProvider),
        userId: ref.read(authStateProvider).userId,
      );
      if (homeStore.hasConfirmedHomeLocation) {
        AppNavigation.navigateToHome();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          DeepLinkRouter.replayPendingAuthenticatedRoute(appGoRouter);
        });
      } else {
        AppNavigation.goLocation();
      }
    } on AppError catch (e) {
      if (!mounted) return;
      if (e.code == 'PHONE_NOT_VERIFIED') {
        ref.read(signInControllerProvider.notifier).clearError();
        final bool verify = await showPhoneNotVerifiedDialog(context);
        if (verify && mounted) {
          startPhoneVerificationOtp(
            phoneE164,
            rememberMe: ref.read(signInControllerProvider).rememberMe,
          );
        }
        return;
      }
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

  void _handleForgotPassword() {
    unawaited(AppNavigation.pushForgotPasswordRequest());
  }

  void _handleSignUp() {
    AppNavigation.goSignUp();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final SignInState signInState = ref.watch(signInControllerProvider);
    final bool isLoading = signInState.isLoading;
    final String? apiError = signInState.error != null
        ? authBannerMessageForError(
            l10n,
            signInState.error!,
            displayedFieldIds: registeredFieldIds,
          )
        : null;

    if (!_phonePrefilled && signInState.lastPhoneNational != null) {
      _phoneController.text = signInState.lastPhoneNational!;
      _phonePrefilled = true;
    }

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
              child: AuthScreenHeader(
                showLogo: true,
                title: l10n.authSignInTitle,
                subtitle: l10n.authSignInSubtitle,
              ),
            ),
          ),
          body: AuthFormScaffold(
            scrollController: _scrollController,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl + keyboardInset,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (apiError != null) ...[
                          ApiErrorBanner(
                            message: apiError,
                            onDismiss: () {
                              ref
                                  .read(signInControllerProvider.notifier)
                                  .clearError();
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AuthTextField(
                          key: _phoneFieldKey,
                          label: l10n.authFieldPhone,
                          hintText: l10n.authFieldPhoneHint,
                          prefixFixedText: '+389',
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.telephoneNumber,
                            AutofillHints.username,
                          ],
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                          validator: (String? v) => validateIfVisible(
                            FormFieldIds.phone,
                            () => AuthValidators.macedonianPhone(l10n, v),
                          ),
                          inputFormatters: const <TextInputFormatter>[
                            MacedonianPhoneFormatter(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AuthTextField(
                          key: _passwordFieldKey,
                          label: l10n.authFieldPassword,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hintText: l10n.authFieldPasswordHint,
                          obscureText: true,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (String? v) => validateIfVisible(
                            FormFieldIds.password,
                            () => AuthValidators.loginPassword(l10n, v),
                          ),
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[AutofillHints.password],
                          enableSuggestions: false,
                          autocorrect: false,
                          onFieldSubmitted: (_) => _handleSignIn(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _RememberMeRow(
                          l10n: l10n,
                          value: signInState.rememberMe,
                          onChanged: (bool v) {
                            ref
                                .read(signInControllerProvider.notifier)
                                .setRememberMe(value: v);
                          },
                          onForgotPassword: _handleForgotPassword,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Semantics(
                          button: true,
                          label: l10n.authSignInCta,
                          child: AppButton.primary(
                            label: l10n.authSignInCta,
                            enabled: !isLoading,
                            onPressed: isLoading ? null : _handleSignIn,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.radius22),
                        Center(
                          child: Semantics(
                            button: true,
                            label:
                                '${l10n.authSignUpPrompt}${l10n.authSignUpLink}',
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
                                    text: l10n.authSignUpPrompt,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.textMuted),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: l10n.authSignUpLink,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.primaryDark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Builder(
                          builder: (BuildContext context) {
                            final Locale? override = ref.watch(
                              appLocaleOverrideProvider,
                            );
                            final Locale effective = resolveAppLocale(
                              override: override,
                              platformLocales:
                                  PlatformDispatcher.instance.locales,
                            );
                            final String languageLabel = _languageDisplayName(
                              l10n,
                              effective,
                            );
                            return Center(
                              child: Semantics(
                                button: true,
                                label: l10n.profileLanguageTile,
                                child: InkWell(
                                  onTap: () {
                                    showAppLanguagePicker(context);
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radius14,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.language_rounded,
                                          size: 22,
                                          color: AppColors.primaryDark,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          languageLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textMuted,
                                                fontWeight: FontWeight.w500,
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

String _languageDisplayName(AppLocalizations l10n, Locale locale) {
  switch (locale.languageCode) {
    case 'mk':
      return l10n.profileLanguageNameMk;
    case 'sq':
      return l10n.profileLanguageNameSq;
    case 'en':
    default:
      return l10n.profileLanguageNameEn;
  }
}

class _RememberMeRow extends StatelessWidget {
  const _RememberMeRow({
    required this.l10n,
    required this.value,
    required this.onChanged,
    required this.onForgotPassword,
  });

  final AppLocalizations l10n;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
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
              label: l10n.authRememberMe,
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
                        l10n.authRememberMe,
                        style: AppTypography.authSubtitle(textTheme).copyWith(
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
              label: l10n.authForgotPassword,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: const Size(44, 44),
                onPressed: onForgotPassword,
                child: Text(
                  l10n.authForgotPassword,
                  style: AppTypography.authTextLink(
                    textTheme,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
