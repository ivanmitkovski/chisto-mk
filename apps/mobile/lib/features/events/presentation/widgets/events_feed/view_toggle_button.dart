import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

const double _kControlSize = 48;
const double _kControlIconSize = 20;
const double _kSelectedBorderAlpha = 0.45;
const double _kUnselectedBorderAlpha = 0.7;

class ViewToggleButton extends StatelessWidget {
  const ViewToggleButton({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Shown as [Tooltip] and as the screen reader label (long-press for tooltip on iOS).
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius10),
            ),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.fast,
              curve: AppMotion.emphasized,
              width: _kControlSize,
              height: _kControlSize,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primaryContainer
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radius10),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: _kSelectedBorderAlpha)
                      : colorScheme.outlineVariant.withValues(alpha: _kUnselectedBorderAlpha),
                ),
              ),
              child: Icon(
                icon,
                size: _kControlIconSize,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
