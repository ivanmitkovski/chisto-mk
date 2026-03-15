import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class ProfilePasswordScreen extends StatefulWidget {
  const ProfilePasswordScreen({super.key});

  @override
  State<ProfilePasswordScreen> createState() => _ProfilePasswordScreenState();
}

class _ProfilePasswordScreenState extends State<ProfilePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _oldObscured = true;
  bool _newObscured = true;
  bool _confirmObscured = true;
  bool _isSubmitting = false;
  bool _hasConfirmError = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isSubmitting) return;

    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _hasConfirmError = true);
      AppSnack.show(
        context,
        message: 'Enter and confirm your new password.',
        type: AppSnackType.warning,
      );
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _hasConfirmError = true);
      AppSnack.show(
        context,
        message: 'Passwords do not match.',
        type: AppSnackType.error,
      );
      return;
    }

    setState(() {
      _hasConfirmError = false;
      _isSubmitting = true;
    });
    AppHaptics.medium();
    await Future<void>.delayed(AppMotion.slow);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    AppSnack.show(
      context,
      message: 'Password updated',
      type: AppSnackType.success,
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppBackButton(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reset password',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Choose a strong, unique password.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _PasswordField(
                        label: 'Old password',
                        controller: _oldPasswordController,
                        obscureText: _oldObscured,
                        isError: false,
                        onToggleVisibility: () {
                          setState(() => _oldObscured = !_oldObscured);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PasswordField(
                        label: 'New password',
                        controller: _newPasswordController,
                        obscureText: _newObscured,
                        isError: false,
                        helperText: 'At least 8 characters, with a number.',
                        onToggleVisibility: () {
                          setState(() => _newObscured = !_newObscured);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PasswordField(
                        label: 'Confirm new password',
                        controller: _confirmPasswordController,
                        obscureText: _confirmObscured,
                        isError: _hasConfirmError,
                        helperText: _hasConfirmError
                            ? 'Make sure this matches the new password above.'
                            : null,
                        onToggleVisibility: () {
                          setState(
                            () => _confirmObscured = !_confirmObscured,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(AppSpacing.radius14),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.9),
                          ),
                        ),
                        child: Text(
                          'For security, avoid reusing passwords from other apps.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: _isSubmitting ? 'Updating…' : 'Reset password',
                onPressed: _isSubmitting ? null : _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.isError,
    required this.onToggleVisibility,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final bool isError;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        isError ? AppColors.error : AppColors.inputBorder;
    final Color focusedBorderColor =
        isError ? AppColors.error : AppColors.primaryDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius18),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius18),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textMuted,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
        if (helperText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isError ? AppColors.error : AppColors.textMuted,
                  height: 1.3,
                ),
          ),
        ],
      ],
    );
  }
}

