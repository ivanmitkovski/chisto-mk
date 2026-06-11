import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  /// When true, shows a spinner and ignores presses (unless [enabled] is false).
  final bool isLoading;
  final Widget? leadingIcon;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool busy = widget.isLoading && widget.enabled;
    final bool canPress = widget.enabled && !busy && widget.onPressed != null;
    final bool inactive = !widget.enabled || widget.onPressed == null;

    return AnimatedScale(
      scale: _pressed && canPress ? 0.985 : 1,
      duration: AppMotion.xFast,
      curve: AppMotion.emphasized,
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Listener(
          onPointerDown: (_) {
            if (canPress) _setPressed(true);
          },
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: ElevatedButton(
            onPressed: canPress ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: busy
                  ? AppColors.primary
                  : (inactive ? AppColors.inputFill : AppColors.primary),
              foregroundColor: busy
                  ? AppColors.textPrimary
                  : (inactive
                        ? AppColors.textSecondary
                        : AppColors.textPrimary),
              side: inactive && !busy
                  ? const BorderSide(color: AppColors.inputBorder)
                  : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: busy
                ? const Center(
                    // heightFactor hugs content so the button keeps its
                    // intrinsic height (>= minHeight) instead of expanding to
                    // fill bounded slots like Scaffold.bottomNavigationBar.
                    heightFactor: 1,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : Center(
                    heightFactor: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (widget.leadingIcon != null) ...<Widget>[
                          widget.leadingIcon!,
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                            style: AppTypography.buttonLabel(textTheme)
                                .copyWith(
                                  color: inactive
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  height: 1,
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
    );
  }
}
