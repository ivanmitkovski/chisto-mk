import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Horizontal step segment: label when active/upcoming; completed (non-active)
/// steps show a check only so the row stays readable.
class StageChip extends StatelessWidget {
  const StageChip({
    super.key,
    required this.label,
    required this.isCurrent,
    required this.isComplete,
    required this.isEnabled,
    required this.onTap,
    required this.stepIndex,
    required this.totalSteps,
  });

  final String label;
  final bool isCurrent;
  final bool isComplete;
  final bool isEnabled;
  final VoidCallback onTap;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final Color background = isCurrent
        ? AppColors.panelBackground
        : AppColors.transparent;
    final Color foreground = isCurrent
        ? AppColors.textPrimary
        : isComplete
        ? AppColors.primaryDark
        : AppColors.textMuted;

    final String statusText = isComplete
        ? 'Complete'
        : isCurrent
        ? 'Current'
        : 'Incomplete';
    final String stepLabel = 'Step ${stepIndex + 1} of $totalSteps, $label';
    final String hint = isEnabled
        ? 'Double-tap to go to $label'
        : 'Complete previous steps first.';
    return Semantics(
      button: true,
      label: '$stepLabel. $statusText.',
      hint: hint,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.55,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.emphasized,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: isCurrent
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: isComplete && !isCurrent
                  ? Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: AppSpacing.iconMd,
                        color: foreground,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: MediaQuery.textScalerOf(context)
                                  .clamp(
                                    minScaleFactor: 0.85,
                                    maxScaleFactor: 1.25,
                                  ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: AppTypography.chipLabel.copyWith(
                                  color: foreground,
                                  letterSpacing: -0.15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
