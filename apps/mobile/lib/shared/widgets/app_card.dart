import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.elevation,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolvedRadius =
        borderRadius ?? BorderRadius.circular(AppSpacing.radiusCard);
    final Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.panelBackground,
        borderRadius: resolvedRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: elevation ?? 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: (elevation ?? 8) / 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}
