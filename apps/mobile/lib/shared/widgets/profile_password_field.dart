import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Labeled password field with visibility toggle (shared profile / auth flows).
class ProfilePasswordField extends StatelessWidget {
  const ProfilePasswordField({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.controller,
    required this.obscureText,
    required this.isError,
    required this.onToggleVisibility,
    required this.toggleVisibilitySemanticLabel,
    this.fieldKey,
    this.focusNode,
    this.helperText,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final String label;
  final String semanticLabel;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String toggleVisibilitySemanticLabel;
  final bool isError;
  final String? helperText;
  final GlobalKey? fieldKey;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isError ? AppColors.error : AppColors.inputBorder;
    final Color focusedBorderColor =
        isError ? AppColors.error : AppColors.primaryDark;

    Widget field = Semantics(
      label: semanticLabel,
      textField: true,
      obscured: obscureText,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
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
          suffixIcon: Semantics(
            button: true,
            toggled: !obscureText,
            label: toggleVisibilitySemanticLabel,
            child: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textMuted,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ),
    );
    if (fieldKey != null) {
      field = RepaintBoundary(key: fieldKey, child: field);
    }

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
        field,
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
