import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/evidence_carousel.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_mock_store.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_card.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class ReportDetailSheet extends StatelessWidget {
  const ReportDetailSheet({super.key, required this.report});

  final MockReport report;

  static String _formatDateFull(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final List<String> evidencePaths = report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage =
        evidencePaths.isNotEmpty && File(evidencePaths.first).existsSync();

    return ReportSheetScaffold(
      title: 'Report details',
      subtitle: 'See what you submitted and how moderators handled this report.',
      trailing: ReportCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: 'Close',
        onTap: () {
          AppHaptics.tap();
          Navigator.of(context).pop();
        },
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (hasEvidenceImage) ...<Widget>[
              EvidenceCarousel(photoPaths: evidencePaths),
              const SizedBox(height: AppSpacing.md),
            ],
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                ReportStatusBadge(status: report.status),
                ReportStatePill(
                  label: _formatDateFull(report.createdAt),
                  icon: Icons.schedule_rounded,
                  tone: ReportSurfaceTone.neutral,
                ),
                if (hasEvidenceImage)
                  const ReportStatePill(
                    label: 'Photo attached',
                    icon: Icons.image_outlined,
                    tone: ReportSurfaceTone.accent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: report.category.icon,
              label: 'Category',
              child: Text(
                report.category.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
              ),
            ),
            if (report.cleanupEffort != null)
              _DetailRow(
                icon: Icons.groups_2_outlined,
                label: 'Cleanup effort',
                child: Text(
                  report.cleanupEffort!.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
            if (report.score > 0)
              _DetailRow(
                icon: Icons.emoji_events_rounded,
                label: 'Points',
                child: Text(
                  '+${report.score}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentWarning,
                  ),
                ),
              ),
            if (report.address != null && report.address!.isNotEmpty)
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                child: Text(
                  report.address!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        letterSpacing: -0.2,
                      ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              report.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.divider.withValues(alpha: 0.7), height: 1),
            const SizedBox(height: AppSpacing.lg),
            ReportInfoBanner(
              title: report.status == ReportStatus.underReview
                  ? 'Under review by moderators'
                  : report.status == ReportStatus.approved
                      ? 'Approved and linked to a site'
                      : report.status == ReportStatus.alreadyReported
                          ? 'Already tracked as an existing site'
                          : 'Review outcome',
              icon: report.status == ReportStatus.approved
                  ? Icons.verified_outlined
                  : report.status == ReportStatus.declined
                      ? Icons.info_outline_rounded
                      : Icons.schedule_rounded,
              tone: report.status == ReportStatus.approved
                  ? ReportSurfaceTone.success
                  : report.status == ReportStatus.declined
                      ? ReportSurfaceTone.danger
                      : report.status == ReportStatus.alreadyReported
                          ? ReportSurfaceTone.warning
                          : ReportSurfaceTone.neutral,
              message: report.status == ReportStatus.underReview
                  ? 'Moderators are checking your evidence and location before they decide how to handle this report.'
                  : report.status == ReportStatus.approved
                      ? 'This report helped confirm a public pollution site and may contribute to cleanup actions.'
                      : report.status == ReportStatus.alreadyReported
                          ? 'Your report matched an existing site. The evidence is still useful for understanding the problem.'
                          : report.declineReason ??
                              'This report could not be approved in its current form.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
