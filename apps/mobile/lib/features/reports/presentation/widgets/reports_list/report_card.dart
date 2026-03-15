import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_mock_store.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    required this.formatDate,
  });

  final MockReport report;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final List<String> evidencePaths = report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage =
        evidencePaths.isNotEmpty && File(evidencePaths.first).existsSync();

    return Semantics(
      button: true,
      label: '${report.title}. ${report.status.label}. Tap to view details.',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider, width: 0.5),
                  boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: hasEvidenceImage
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    AppSmartImage(
                                      image: FileImage(
                                        File(evidencePaths.first),
                                      ),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            AppColors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            AppColors.black.withValues(
                                              alpha: 0.24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: Icon(
                                    report.category.icon,
                                    size: 28,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: <Widget>[
                                      ReportStatusBadge(status: report.status),
                                      Text(
                                        formatDate(report.createdAt),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    if (report.score > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.emoji_events_rounded,
                                            size: AppSpacing.iconSm,
                                            color: AppColors.accentWarning,
                                          ),
                                          const SizedBox(width: AppSpacing.xxs),
                                          Text(
                                            '+${report.score}',
                                            style: AppTypography.chipLabel.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accentWarning,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 22,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            if (hasEvidenceImage)
                              const ReportStatePill(
                                label: 'Photo attached',
                                icon: Icons.image_outlined,
                                tone: ReportSurfaceTone.neutral,
                              ),
                            if (hasEvidenceImage) const SizedBox(height: AppSpacing.xs),
                            Text(
                              report.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                            ),
                            if (report.address != null &&
                                report.address!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Expanded(
                                    child: Text(
                                      report.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (report.declineReason != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    ReportInfoBanner(
                      title: 'Review note',
                      message: report.declineReason!,
                      icon: Icons.info_outline_rounded,
                      tone: ReportSurfaceTone.warning,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
