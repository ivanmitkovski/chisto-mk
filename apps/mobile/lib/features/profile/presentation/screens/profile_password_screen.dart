import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_error_messages.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/validation/input_validators.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_sub_screen_header.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_primary_action_bar.dart';
import 'package:chisto_mobile/shared/widgets/keyboard_aware_form_scroll.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/shared/widgets/profile_password_field.dart';

class ProfilePasswordScreen extends StatefulWidget {
  const ProfilePasswordScreen({super.key});

  @override
  State<ProfilePasswordScreen> createState() => _ProfilePasswordScreenState();
}

class _ProfilePasswordScreenState extends State<ProfilePasswordScreen> {
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
  bool _hasConfirmError = false;

  @override
  void initState() {
    super.initState();
    _oldFocus.addListener(_scrollToFocusedField);
    _newFocus.addListener(_scrollToFocusedField);
    _confirmFocus.addListener(_scrollToFocusedField);
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

    final String currentPassword = _oldPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      AppSnack.show(
        context,
        message: context.l10n.profilePasswordEnterCurrentWarning,
        type: AppSnackType.warning,
      );
      return;
    }
    final String? newError = InputValidators.validatePassword(newPassword);
    if (newError != null) {
      AppSnack.show(context, message: newError, type: AppSnackType.warning);
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _hasConfirmError = true);
      AppSnack.show(
        context,
        message: context.l10n.profilePasswordMismatchError,
        type: AppSnackType.error,
      );
      return;
    }

    setState(() {
      _hasConfirmError = false;
      _isSubmitting = true;
    });
    AppHaptics.medium();

    try {
      await ServiceLocator.instance.authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _hasConfirmError = false;
      });
      AppSnack.show(
        context,
        message: context.l10n.profilePasswordSuccess,
        type: AppSnackType.success,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final String message =
          e.code == 'UNAUTHORIZED' || e.code == 'INVALID_TOKEN_USER'
          ? context.l10n.profilePasswordSessionExpired
          : messageForAuthError(context.l10n, e);
      AppSnack.show(context, message: message, type: AppSnackType.error);
      if (e.code == 'UNAUTHORIZED' || e.code == 'INVALID_TOKEN_USER') {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnack.show(
        context,
        message: context.l10n.profilePasswordGenericError,
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: ProfilePrimaryActionBar(
        padForKeyboard: false,
        child: PrimaryButton(
          label: _isSubmitting
              ? context.l10n.profilePasswordSubmitting
              : context.l10n.profilePasswordSubmit,
          onPressed: _isSubmitting ? null : _handleReset,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProfileSubScreenHeader(
              title: context.l10n.profilePasswordScreenTitle,
              subtitle: context.l10n.profilePasswordScreenSubtitle,
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
                      semanticLabel:
                          context.l10n.profilePasswordCurrentSemantic,
                      label: context.l10n.profilePasswordCurrentLabel,
                      controller: _oldPasswordController,
                      obscureText: _oldObscured,
                      isError: false,
                      textInputAction: TextInputAction.next,
                      toggleVisibilitySemanticLabel:
                          context.l10n.profilePasswordToggleVisibility,
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
                      semanticLabel: context.l10n.profilePasswordNewSemantic,
                      label: context.l10n.profilePasswordNewLabel,
                      controller: _newPasswordController,
                      obscureText: _newObscured,
                      isError: false,
                      helperText: context.l10n.profilePasswordNewHelper,
                      textInputAction: TextInputAction.next,
                      toggleVisibilitySemanticLabel:
                          context.l10n.profilePasswordToggleVisibility,
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
                      semanticLabel:
                          context.l10n.profilePasswordConfirmSemantic,
                      label: context.l10n.profilePasswordConfirmLabel,
                      controller: _confirmPasswordController,
                      obscureText: _confirmObscured,
                      isError: _hasConfirmError,
                      helperText: _hasConfirmError
                          ? context
                              .l10n.profilePasswordConfirmMismatchHelper
                          : null,
                      textInputAction: TextInputAction.done,
                      toggleVisibilitySemanticLabel:
                          context.l10n.profilePasswordToggleVisibility,
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
                          color: AppColors.divider.withValues(
                            alpha: 0.9,
                          ),
                        ),
                      ),
                      child: Text(
                        context.l10n.profilePasswordSecurityHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.35,
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
