import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class SwipeActionBackground extends StatelessWidget {
  const SwipeActionBackground({
    super.key,
    required this.icon,
    required this.label,
    required this.alignment,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool left = alignment == Alignment.centerLeft;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.radius18),
          ),
          child: SizedBox.expand(
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: left ? AppSpacing.md : AppSpacing.lg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                      left ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: <Widget>[
                    if (!left) ...<Widget>[
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Icon(icon, size: 20, color: color),
                    if (left) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
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
