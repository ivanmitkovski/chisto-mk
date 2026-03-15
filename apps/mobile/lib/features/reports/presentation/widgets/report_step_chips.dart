import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class ReportStepChips extends StatelessWidget {
  const ReportStepChips({
    super.key,
    required this.hasPhotos,
    required this.hasCategory,
    required this.hasLocation,
    this.nextStepLabel,
  });

  final bool hasPhotos;
  final bool hasCategory;
  final bool hasLocation;
  final String? nextStepLabel;

  int get _currentStep {
    final int done = [
      hasPhotos,
      hasCategory,
      hasLocation,
    ].where((bool v) => v).length;
    return (done + 1).clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    final bool isComplete = hasPhotos && hasCategory && hasLocation;
    final int completedCount = <bool>[
      hasPhotos,
      hasCategory,
      hasLocation,
    ].where((bool value) => value).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              isComplete ? 'Ready to submit' : 'Step $_currentStep of 3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: -0.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.emphasized,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
              ),
              child: Text(
                isComplete ? 'Complete' : 'In progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isComplete
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: _StepChip(
                index: 1,
                label: 'Photos',
                isDone: hasPhotos,
                isCurrent: !hasPhotos,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _StepChip(
                index: 2,
                label: 'Category',
                isDone: hasCategory,
                isCurrent: hasPhotos && !hasCategory,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _StepChip(
                index: 3,
                label: 'Location',
                isDone: hasLocation,
                isCurrent: hasPhotos && hasCategory && !hasLocation,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: completedCount / 3,
            minHeight: 4,
            backgroundColor: AppColors.inputFill,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryDark,
            ),
          ),
        ),
        if (nextStepLabel != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            nextStepLabel!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final int index;
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final Color bg = isDone
        ? AppColors.primary.withValues(alpha: 0.12)
        : isCurrent
        ? AppColors.primaryDark.withValues(alpha: 0.08)
        : AppColors.inputFill;
    final Color fg = isDone || isCurrent
        ? AppColors.primaryDark
        : AppColors.textSecondary;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDone
              ? AppColors.primary.withValues(alpha: 0.4)
              : isCurrent
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.divider,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : AppColors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: fg, width: 1.1),
            ),
            child: Center(
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: AppColors.white,
                    )
                  : Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: fg,
                        letterSpacing: -0.1,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: -0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
