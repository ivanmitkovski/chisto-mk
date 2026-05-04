import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Copy for the bottom status explainer on the report detail sheet.
final class ReportDetailStatusBannerData {
  const ReportDetailStatusBannerData({
    required this.title,
    required this.message,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String message;
  final IconData icon;
  final ReportSurfaceTone tone;
}

ReportDetailStatusBannerData reportDetailStatusBannerData(
  AppLocalizations l10n,
  ReportSheetViewModel report,
) {
  switch (report.status) {
    case ReportSheetStatus.underReview:
      return ReportDetailStatusBannerData(
        title: l10n.reportDetailStatusUnderReviewTitle,
        message: l10n.reportDetailStatusUnderReviewBody,
        icon: Icons.schedule_rounded,
        tone: ReportSurfaceTone.neutral,
      );
    case ReportSheetStatus.approved:
      return ReportDetailStatusBannerData(
        title: l10n.reportDetailStatusApprovedTitle,
        message: l10n.reportDetailStatusApprovedBody,
        icon: Icons.verified_outlined,
        tone: ReportSurfaceTone.success,
      );
    case ReportSheetStatus.alreadyReported:
      return ReportDetailStatusBannerData(
        title: l10n.reportDetailStatusAlreadyReportedTitle,
        message: l10n.reportDetailStatusAlreadyReportedBody,
        icon: Icons.schedule_rounded,
        tone: ReportSurfaceTone.warning,
      );
    case ReportSheetStatus.declined:
      return ReportDetailStatusBannerData(
        title: l10n.reportDetailStatusOutcomeTitle,
        message:
            report.declineReason ?? l10n.reportDetailStatusOutcomeBodyFallback,
        icon: Icons.info_outline_rounded,
        tone: ReportSurfaceTone.danger,
      );
  }
}
