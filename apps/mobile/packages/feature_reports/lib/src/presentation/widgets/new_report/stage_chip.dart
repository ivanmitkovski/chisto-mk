import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final Color background = isCurrent
        ? AppColors.panelBackground
        : AppColors.transparent;
    final Color foreground = isCurrent
        ? AppColors.textPrimary
        : isComplete
        ? AppColors.primaryDark
        : AppColors.textMuted;

    final String statusText = isComplete
        ? l10n.reportFlowStepStatusComplete
        : l10n.reportFlowStepStatusInProgress;
    final String hint = isEnabled
        ? l10n.semanticsNextStep(label)
        : l10n.reportReviewAfterSubmitIncomplete;
    return Semantics(
      button: true,
      label: '$label. $statusText.',
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
                    ? AppShadows.panel(Theme.of(context).colorScheme)
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
                                style: AppTypography.chipLabel(textTheme)
                                    .copyWith(
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
