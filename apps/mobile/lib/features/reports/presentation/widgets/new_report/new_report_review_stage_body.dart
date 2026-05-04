import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/cleanup_effort_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_category_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_severity_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/review_summary_tile.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:flutter/material.dart';

/// Review step: summary tiles + submit readiness banners.
class NewReportReviewStageBody extends StatelessWidget {
  const NewReportReviewStageBody({
    super.key,
    required this.draft,
    required this.hasValidLocation,
    required this.canSubmit,
    required this.reportCapacity,
    required this.onGoToEvidence,
    required this.onGoToDetails,
    required this.onGoToLocation,
  });

  final ReportDraft draft;
  final bool hasValidLocation;
  final bool canSubmit;
  final ReportCapacity? reportCapacity;
  final VoidCallback onGoToEvidence;
  final VoidCallback onGoToDetails;
  final VoidCallback onGoToLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ReviewSummaryTile(
          icon: Icons.photo_library_outlined,
          title: context.l10n.reportReviewEvidenceTitle,
          subtitle: draft.hasPhotos
              ? context.l10n.reportReviewPhotoCount(draft.photos.length)
              : context.l10n.reportReviewAddPhoto,
          isComplete: draft.hasPhotos,
          semanticsHint: context.l10n.reviewTapToEdit,
          onTap: onGoToEvidence,
        ),
        const SizedBox(height: AppSpacing.sm),
        ReviewSummaryTile(
          icon: draft.category?.icon ?? Icons.category_outlined,
          title: context.l10n.reportReviewCategoryTitle,
          subtitle: draft.category?.localizedTitle(context.l10n) ??
              context.l10n.reportReviewChooseCategory,
          isComplete: draft.hasCategory,
          semanticsHint: context.l10n.reviewTapToEdit,
          onTap: onGoToDetails,
        ),
        const SizedBox(height: AppSpacing.sm),
        ReviewSummaryTile(
          icon: Icons.title_rounded,
          title: context.l10n.reportReviewTitleLabel,
          subtitle: draft.hasTitle
              ? draft.title.trim()
              : context.l10n.reportReviewAddTitle,
          isComplete: draft.hasTitle,
          semanticsHint: context.l10n.reviewTapToEdit,
          onTap: onGoToDetails,
        ),
        const SizedBox(height: AppSpacing.sm),
        ReviewSummaryTile(
          icon: Icons.signal_cellular_alt,
          title: context.l10n.reportReviewSeverityTitle,
          subtitle: reportSeverityDisplayLabel(context.l10n, draft.severity),
          isComplete: true,
          isOptional: true,
          semanticsHint: context.l10n.reviewTapToEdit,
          onTap: onGoToDetails,
        ),
        const SizedBox(height: AppSpacing.sm),
        ReviewSummaryTile(
          icon: Icons.location_on_outlined,
          title: context.l10n.reportReviewLocationTitle,
          subtitle: hasValidLocation
              ? (draft.address ?? context.l10n.reportReviewPinnedShort)
              : context.l10n.reportReviewPinMacedonia,
          isComplete: hasValidLocation,
          semanticsHint: context.l10n.reviewTapToEdit,
          onTap: onGoToLocation,
        ),
        if (draft.hasDescription) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ReviewSummaryTile(
            icon: Icons.notes_outlined,
            title: context.l10n.reportReviewExtraContextTitle,
            subtitle: draft.description.trim(),
            isComplete: true,
            isOptional: true,
            semanticsHint: context.l10n.reviewTapToEdit,
            onTap: onGoToDetails,
          ),
        ],
        if (draft.cleanupEffort != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ReviewSummaryTile(
            icon: Icons.group_outlined,
            title: context.l10n.reportReviewCleanupEffortTitle,
            subtitle: draft.cleanupEffort!.localizedLabel(context.l10n),
            isComplete: true,
            isOptional: true,
            semanticsHint: context.l10n.reviewTapToEdit,
            onTap: onGoToDetails,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ReportInfoBanner(
          title: context.l10n.reportReviewBannerAfterSubmitTitle,
          icon: Icons.verified_user_outlined,
          tone: canSubmit
              ? ReportSurfaceTone.neutral
              : ReportSurfaceTone.warning,
          message: canSubmit
              ? context.l10n.reportReviewAfterSubmitReady
              : context.l10n.reportReviewAfterSubmitIncomplete,
        ),
        if (reportCapacity != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (BuildContext context) {
              final ReportCapacityUiState ui = mapReportCapacityToUiState(
                reportCapacity!,
                l10n: context.l10n,
                nextEmergencyAvailableDescription:
                    formatNextEmergencyUnlockLocal(
                  context,
                  reportCapacity!.nextEmergencyReportAvailableAt,
                ),
              );
              return ReportInfoBanner(
                title: context.l10n.reportReviewBannerCreditsTitle,
                emphasis: ReportInfoBannerEmphasis.secondary,
                icon: ui.pillIcon,
                tone: ui.pillTone,
                message: ui.reviewMessage,
              );
            },
          ),
        ],
      ],
    );
  }
}
