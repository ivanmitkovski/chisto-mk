import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  /// When true, shows a spinner and ignores presses (unless [enabled] is false).
  final bool isLoading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool busy = widget.isLoading && widget.enabled;
    final bool canPress = widget.enabled && !busy && widget.onPressed != null;
    final bool inactive = !widget.enabled || widget.onPressed == null;

    return AnimatedScale(
      scale: _pressed && canPress ? 0.985 : 1,
      duration: AppMotion.xFast,
      curve: AppMotion.emphasized,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Listener(
          onPointerDown: (_) {
            if (canPress) {
              setState(() => _pressed = true);
            }
          },
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
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
                  : (inactive ? AppColors.textSecondary : AppColors.textPrimary),
              side: inactive && !busy
                  ? const BorderSide(color: AppColors.inputBorder)
                  : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: busy
                ? Center(
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
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                      style: AppTypography.buttonLabel.copyWith(
                        color: inactive
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
