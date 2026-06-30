import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_radii.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:design_system/src/widgets/atoms/app_loading_indicator.dart';
import 'package:design_system/src/widgets/atoms/primary_button.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outlined, text, destructive }

enum AppButtonSize { regular, compact }

/// Unified CTA — replaces raw Material buttons in features.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.enabled = true,
    this.isLoading = false,
    this.leadingIcon,
    this.expand = true,
  });

  factory AppButton.primary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool enabled = true,
    bool isLoading = false,
    bool expand = true,
    Widget? leadingIcon,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.primary,
    enabled: enabled,
    isLoading: isLoading,
    expand: expand,
    leadingIcon: leadingIcon,
  );

  factory AppButton.secondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool enabled = true,
    bool isLoading = false,
    bool expand = true,
    Widget? leadingIcon,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.secondary,
    enabled: enabled,
    isLoading: isLoading,
    expand: expand,
    leadingIcon: leadingIcon,
  );

  factory AppButton.outlined({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool enabled = true,
    bool isLoading = false,
    bool expand = false,
    Widget? leadingIcon,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.outlined,
    enabled: enabled,
    isLoading: isLoading,
    expand: expand,
    leadingIcon: leadingIcon,
  );

  factory AppButton.text({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool enabled = true,
    bool expand = false,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.text,
    enabled: enabled,
    expand: expand,
  );

  factory AppButton.destructive({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool enabled = true,
    bool isLoading = false,
    bool expand = true,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.destructive,
    enabled: enabled,
    isLoading: isLoading,
    expand: expand,
  );

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool enabled;
  final bool isLoading;
  final Widget? leadingIcon;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == AppButtonVariant.primary && widget.expand) {
      return PrimaryButton(
        label: widget.label,
        onPressed: widget.onPressed,
        enabled: widget.enabled,
        isLoading: widget.isLoading,
        leadingIcon: widget.leadingIcon,
      );
    }

    final bool busy = widget.isLoading && widget.enabled;
    final bool canPress = widget.enabled && !busy && widget.onPressed != null;
    final double height = widget.size == AppButtonSize.compact ? 44 : 52;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget child = _buildChild(textTheme, busy, canPress, height);

    if (!widget.expand) {
      return child;
    }
    return SizedBox(width: double.infinity, child: child);
  }

  Widget _buildChild(
    TextTheme textTheme,
    bool busy,
    bool canPress,
    double height,
  ) {
    final TextStyle labelStyle = AppTypography.buttonLabel(
      textTheme,
    ).copyWith(color: _foregroundColor(busy, canPress), height: 1);

    final Widget labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.leadingIcon != null && !busy) ...<Widget>[
          widget.leadingIcon!,
          const SizedBox(width: AppSpacing.xs),
        ],
        if (busy)
          AppLoadingIndicator(
            size: widget.size == AppButtonSize.compact
                ? AppLoadingIndicatorSize.sm
                : AppLoadingIndicatorSize.md,
            color: _foregroundColor(busy, canPress),
          )
        else if (widget.expand)
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          )
        else
          Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: labelStyle,
          ),
      ],
    );

    return AnimatedScale(
      scale: _pressed && canPress ? 0.985 : 1,
      duration: AppMotion.xFast,
      curve: AppMotion.emphasized,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Listener(
          onPointerDown: (_) {
            if (canPress) _setPressed(true);
          },
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: Material(
            color: _backgroundColor(busy, canPress),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.pill,
              side: _borderSide(canPress),
            ),
            child: InkWell(
              onTap: canPress ? widget.onPressed : null,
              borderRadius: AppRadii.pill,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Center(child: labelRow),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(bool busy, bool canPress) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return canPress || busy ? AppColors.primary : AppColors.inputFill;
      case AppButtonVariant.secondary:
        return canPress || busy
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.inputFill;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppColors.transparent;
      case AppButtonVariant.destructive:
        return canPress || busy ? AppColors.accentDanger : AppColors.inputFill;
    }
  }

  Color _foregroundColor(bool busy, bool canPress) {
    if (!canPress && !busy) {
      return AppColors.textSecondary;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.textPrimary;
      case AppButtonVariant.secondary:
        return AppColors.primaryDark;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppColors.primaryDark;
      case AppButtonVariant.destructive:
        return AppColors.textOnDark;
    }
  }

  BorderSide _borderSide(bool canPress) {
    switch (widget.variant) {
      case AppButtonVariant.outlined:
        return BorderSide(
          color: canPress ? AppColors.inputBorder : AppColors.divider,
        );
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
      case AppButtonVariant.destructive:
        if (!canPress && widget.variant != AppButtonVariant.text) {
          return const BorderSide(color: AppColors.inputBorder);
        }
        return BorderSide.none;
    }
  }
}
