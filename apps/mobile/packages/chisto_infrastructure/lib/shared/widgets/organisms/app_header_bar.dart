import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

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
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding:
          padding ??
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
                style: AppTypography.cardTitle(
                  textTheme,
                ).copyWith(fontWeight: FontWeight.w700),
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
                : Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}
