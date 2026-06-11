import 'dart:async';

import 'package:chisto_infrastructure/core/auth/session_invalidation.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/forms.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_profile/src/presentation/providers/profile_providers.dart';
import 'package:feature_profile/src/presentation/widgets/profile_primary_action_bar.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePasswordScreen extends ConsumerStatefulWidget {
  const ProfilePasswordScreen({super.key});

  @override
  ConsumerState<ProfilePasswordScreen> createState() =>
      _ProfilePasswordScreenState();
}

class _ProfilePasswordScreenState extends ConsumerState<ProfilePasswordScreen>
    with FormValidationMixin {
  static const List<String> _fieldOrder = <String>[
    FormFieldIds.currentPassword,
    FormFieldIds.newPassword,
    FormFieldIds.confirmPassword,
  ];

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _oldFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final GlobalKey _oldFieldKey = GlobalKey();
  final GlobalKey _newFieldKey = GlobalKey();
  final GlobalKey _confirmFieldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  bool _oldObscured = true;
  bool _newObscured = true;
  bool _confirmObscured = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    registerFormField(
      FormFieldIds.currentPassword,
      focusNode: _oldFocus,
      fieldKey: _oldFieldKey,
    );
    registerFormField(
      FormFieldIds.newPassword,
      focusNode: _newFocus,
      fieldKey: _newFieldKey,
    );
    registerFormField(
      FormFieldIds.confirmPassword,
      focusNode: _confirmFocus,
      fieldKey: _confirmFieldKey,
    );
    _oldPasswordController.addListener(_onFieldChanged);
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _oldFocus.addListener(_scrollToFocusedField);
    _newFocus.addListener(_scrollToFocusedField);
    _confirmFocus.addListener(_scrollToFocusedField);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Map<String, String? Function()> _validators(AppLocalizations l10n) {
    final String newPassword = _newPasswordController.text;
    return <String, String? Function()>{
      FormFieldIds.currentPassword: () =>
          FormValidators.loginPassword(l10n, _oldPasswordController.text),
      FormFieldIds.newPassword: () =>
          FormValidators.strongPassword(l10n, newPassword),
      FormFieldIds.confirmPassword: () => FormValidators.confirmPassword(
        l10n,
        newPassword,
      )(_confirmPasswordController.text),
    };
  }

  String? _fieldError(AppLocalizations l10n, String id) {
    final Map<String, String? Function()> validators = _validators(l10n);
    final String? Function()? validate = validators[id];
    if (validate == null) return null;
    return validateIfVisible(id, validate);
  }

  void _scrollToFocusedField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? ctx = _oldFocus.hasFocus
          ? _oldFieldKey.currentContext
          : _newFocus.hasFocus
          ? _newFieldKey.currentContext
          : _confirmFocus.hasFocus
          ? _confirmFieldKey.currentContext
          : null;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: AppMotion.medium,
          curve: AppMotion.smooth,
        );
      }
    });
  }

  @override
  void dispose() {
    _oldPasswordController.removeListener(_onFieldChanged);
    _newPasswordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _oldFocus.removeListener(_scrollToFocusedField);
    _newFocus.removeListener(_scrollToFocusedField);
    _confirmFocus.removeListener(_scrollToFocusedField);
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    _scrollController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isSubmitting) return;

    clearServerFieldErrors();
    final AppLocalizations l10n = context.l10n;
    if (await handleInvalidSubmit(
      context,
      l10n,
      _fieldOrder,
      _validators(l10n),
    )) {
      return;
    }

    final String currentPassword = _oldPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      AppSnack.show(
        context,
        message: l10n.profilePasswordSuccess,
        type: AppSnackType.success,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final Map<String, String> fieldErrors = fieldErrorsFromAppError(e, l10n);
      if (fieldErrors.isNotEmpty) {
        setServerFieldErrors(fieldErrors);
        await focusAndScrollToFirstInvalid(
          context,
          _fieldOrder,
          _validators(l10n),
        );
        return;
      }
      if (SessionInvalidation.shouldHandle(e)) {
        unawaited(SessionInvalidation.fromError(e));
        return;
      }
      AppSnack.show(
        context,
        message: messageForAuthError(l10n, e),
        type: AppSnackType.error,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnack.show(
        context,
        message: l10n.profilePasswordGenericError,
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? currentError = _fieldError(
      l10n,
      FormFieldIds.currentPassword,
    );
    final String? newError = _fieldError(l10n, FormFieldIds.newPassword);
    final String? confirmError = _fieldError(
      l10n,
      FormFieldIds.confirmPassword,
    );

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: ProfilePrimaryActionBar(
        padForKeyboard: false,
        child: PrimaryButton(
          label: _isSubmitting
              ? l10n.profilePasswordSubmitting
              : l10n.profilePasswordSubmit,
          onPressed: _isSubmitting ? null : _handleReset,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProfileSubScreenHeader(
              title: l10n.profilePasswordScreenTitle,
              subtitle: l10n.profilePasswordScreenSubtitle,
            ),
            Expanded(
              child: KeyboardAwareFormScroll(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ProfilePasswordField(
                      fieldKey: _oldFieldKey,
                      focusNode: _oldFocus,
                      semanticLabel: l10n.profilePasswordCurrentSemantic,
                      label: l10n.profilePasswordCurrentLabel,
                      controller: _oldPasswordController,
                      obscureText: _oldObscured,
                      isError: currentError != null,
                      helperText: currentError,
                      textInputAction: TextInputAction.next,
                      toggleVisibilitySemanticLabel:
                          l10n.profilePasswordToggleVisibility,
                      onSubmitted: () =>
                          FocusScope.of(context).requestFocus(_newFocus),
                      onToggleVisibility: () {
                        setState(() => _oldObscured = !_oldObscured);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ProfilePasswordField(
                      fieldKey: _newFieldKey,
                      focusNode: _newFocus,
                      semanticLabel: l10n.profilePasswordNewSemantic,
                      label: l10n.profilePasswordNewLabel,
                      controller: _newPasswordController,
                      obscureText: _newObscured,
                      isError: newError != null,
                      helperText: newError ?? l10n.profilePasswordNewHelper,
                      textInputAction: TextInputAction.next,
                      toggleVisibilitySemanticLabel:
                          l10n.profilePasswordToggleVisibility,
                      onSubmitted: () =>
                          FocusScope.of(context).requestFocus(_confirmFocus),
                      onToggleVisibility: () {
                        setState(() => _newObscured = !_newObscured);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ProfilePasswordField(
                      fieldKey: _confirmFieldKey,
                      focusNode: _confirmFocus,
                      semanticLabel: l10n.profilePasswordConfirmSemantic,
                      label: l10n.profilePasswordConfirmLabel,
                      controller: _confirmPasswordController,
                      obscureText: _confirmObscured,
                      isError: confirmError != null,
                      helperText: confirmError,
                      textInputAction: TextInputAction.done,
                      toggleVisibilitySemanticLabel:
                          l10n.profilePasswordToggleVisibility,
                      onSubmitted: _handleReset,
                      onToggleVisibility: () {
                        setState(() => _confirmObscured = !_confirmObscured);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radius14,
                        ),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Text(
                        l10n.profilePasswordSecurityHint,
                        style: AppTypographySurfaces.profilePasswordHint(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
