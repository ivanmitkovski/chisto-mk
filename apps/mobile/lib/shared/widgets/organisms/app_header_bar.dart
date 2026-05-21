import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';

/// Standard screen title row: back affordance, centered title, optional trailing.
class AppHeaderBar extends StatelessWidget {
  const AppHeaderBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.showBack = true,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;
  final EdgeInsetsGeometry? padding;

  static const double _trailingSlotWidth = 44;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
      child: Row(
        children: <Widget>[
          if (showBack)
            AppBackButton(onPressed: onBack)
          else
            const SizedBox(width: _trailingSlotWidth),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: _trailingSlotWidth,
            child: trailing == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
          ),
        ],
      ),
    );
  }
}
