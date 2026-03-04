import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: ElevatedButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor:
                  widget.enabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.42),
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
