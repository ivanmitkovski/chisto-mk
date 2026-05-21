import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/validation/password_strength.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.strength});

  final PasswordStrength strength;

  static const double _segmentHeight = 4.0;
  static const int _segmentCount = 3;

  Color get _neutralColor => AppColors.inputBorder;
  Color get _weakColor => AppColors.accentDanger;
  Color get _fairColor => AppColors.accentWarning;
  Color get _strongColor => AppColors.primaryDark;

  int get _filledCount => switch (strength) {
        PasswordStrength.none => 0,
        PasswordStrength.weak => 1,
        PasswordStrength.fair => 2,
        PasswordStrength.strong => 3,
      };

  Color get _activeColor => switch (strength) {
        PasswordStrength.none => _neutralColor,
        PasswordStrength.weak => _weakColor,
        PasswordStrength.fair => _fairColor,
        PasswordStrength.strong => _strongColor,
      };

  @override
  Widget build(BuildContext context) {
    final int filled = _filledCount;
    final Color activeColor = _activeColor;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: List<Widget>.generate(_segmentCount, (int i) {
          final bool isFilled = i < filled;
          final Color color = isFilled ? activeColor : _neutralColor;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < _segmentCount - 1 ? AppSpacing.radiusSm : 0),
              height: _segmentHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(_segmentHeight / 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
