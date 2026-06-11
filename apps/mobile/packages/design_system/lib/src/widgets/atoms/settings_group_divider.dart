import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Hairline between grouped settings-style rows; inset aligns with row title text.
class SettingsGroupDivider extends StatelessWidget {
  const SettingsGroupDivider({super.key});

  /// [SettingsListTile] horizontal padding + icon + gap (matches [AppSpacing.avatarLg]).
  static const double leadingInset = AppSpacing.avatarLg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: leadingInset),
        Expanded(
          child: ColoredBox(
            color: AppColors.divider.withValues(alpha: 0.9),
            child: const SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}
