import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/presentation/theme/report_tokens.dart';
import 'package:flutter/material.dart';

/// Label + value row used in [ReportDetailSheet] (optionally tappable).
class ReportDetailRow extends StatelessWidget {
  const ReportDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticsValue,
    required this.child,
    this.isLast = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticsValue;
  final Widget child;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget row = Semantics(
      container: true,
      label: '$label: $semanticsValue',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: AppSpacing.iconMd, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: ReportTokens.detailRowLabelWidth,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.35),
              ),
              child: Text(
                label,
                style: AppTypographySurfaces.reportsRowLabel(textTheme),
                textAlign: TextAlign.left,
                maxLines: 4,
                softWrap: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.xs),
              child: Icon(
                Icons.chevron_right_rounded,
                size: AppSpacing.iconMd,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
    if (onTap != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.primary.withValues(alpha: 0.06),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: row,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: row,
    );
  }
}
