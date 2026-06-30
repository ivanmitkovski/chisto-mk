import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

String _retryDurationWithPeriod(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return t;
  if (t.endsWith('.') || t.endsWith('。')) return t;
  return '$t.';
}

/// Styled reporting-cooldown message (matches app cards / primary button).
class ReportingCooldownDialog extends StatelessWidget {
  const ReportingCooldownDialog({super.key, required this.retryDurationText});

  final String retryDurationText;

  @override
  Widget build(BuildContext context) {
    const TextTheme textTheme = AppTypography.textTheme;
    final TextStyle? bodyStyle = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      height: 1.45,
    );
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.95)),
          boxShadow: AppShadows.reportModal(),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentWarning.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.radius14),
                    child: Icon(
                      Icons.timer_off_rounded,
                      size: 28,
                      color: AppColors.accentWarningDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.reportCooldownTitle,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.reportCooldownModalIntro,
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.reportCooldownModalRetryLead,
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                label:
                    '${context.l10n.reportCooldownModalRetryLead} $retryDurationText',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primaryDark.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      _retryDurationWithPeriod(retryDurationText),
                      textAlign: TextAlign.center,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.reportCapacityUnlockHint,
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: context.l10n.commonGotIt,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
