import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// iOS-style editor chrome: leading action, centered content, trailing action.
///
/// Side actions size to their label (no fixed width) and each receive equal
/// horizontal space so long localized strings stay fully visible.
class AppEditorTopBar extends StatelessWidget {
  const AppEditorTopBar({
    super.key,
    this.leadingLabel,
    this.onLeadingPressed,
    this.leadingEnabled = true,
    this.leadingSemanticLabel,
    this.trailingLabel,
    this.onTrailingPressed,
    this.trailingEnabled = true,
    this.trailingSemanticLabel,
    this.center,
    this.padding,
  });

  final String? leadingLabel;
  final VoidCallback? onLeadingPressed;
  final bool leadingEnabled;
  final String? leadingSemanticLabel;

  final String? trailingLabel;
  final VoidCallback? onTrailingPressed;
  final bool trailingEnabled;
  final String? trailingSemanticLabel;

  final Widget? center;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _AppEditorTopBarAction(
                label: leadingLabel,
                onPressed: onLeadingPressed,
                enabled: leadingEnabled,
                semanticLabel: leadingSemanticLabel,
                textAlign: TextAlign.start,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: center ?? const SizedBox.shrink(),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _AppEditorTopBarAction(
                label: trailingLabel,
                onPressed: onTrailingPressed,
                enabled: trailingEnabled,
                semanticLabel: trailingSemanticLabel,
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppEditorTopBarAction extends StatelessWidget {
  const _AppEditorTopBarAction({
    required this.label,
    required this.onPressed,
    required this.enabled,
    required this.textAlign,
    this.semanticLabel,
  });

  final String? label;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? semanticLabel;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final String? resolvedLabel = label?.trim();
    if (resolvedLabel == null || resolvedLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle labelStyle = AppTypography.buttonLabel(textTheme).copyWith(
      color: enabled ? AppColors.primaryDark : AppColors.textSecondary,
      fontWeight: FontWeight.w400,
      fontSize: 17,
      height: 1.18,
      letterSpacing: -0.41,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? resolvedLabel,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          minimumSize: const Size(48, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          resolvedLabel,
          style: labelStyle,
          textAlign: textAlign,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
