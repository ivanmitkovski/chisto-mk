import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

class ReviewSummaryTile extends StatelessWidget {
  const ReviewSummaryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.onTap,
    this.isOptional = false,
    this.semanticsHint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComplete;
  final VoidCallback onTap;
  final bool isOptional;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final ReportSurfaceTone tone = isOptional
        ? ReportSurfaceTone.neutral
        : isComplete
        ? ReportSurfaceTone.neutral
        : ReportSurfaceTone.warning;

    return ReportActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      tone: tone,
      semanticsHint: semanticsHint,
      trailing: Icon(
        isOptional
            ? Icons.chevron_right_rounded
            : isComplete
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
        color: isOptional
            ? AppColors.textMuted
            : isComplete
            ? AppColors.primaryDark
            : AppColors.accentWarningDark,
        size: 22,
      ),
      onTap: onTap,
    );
  }
}
