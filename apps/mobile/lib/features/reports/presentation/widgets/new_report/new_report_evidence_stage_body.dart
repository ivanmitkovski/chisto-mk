import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/report_field_limits.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/evidence_tip_card.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_grid.dart';
import 'package:flutter/material.dart';

/// Evidence step content (tip card + photo grid + validation hint).
class NewReportEvidenceStageBody extends StatelessWidget {
  const NewReportEvidenceStageBody({
    super.key,
    required this.draft,
    required this.evidenceTipDismissed,
    required this.attemptedStages,
    required this.onDismissTip,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final ReportDraft draft;
  final bool evidenceTipDismissed;
  final Set<ReportStage> attemptedStages;
  final VoidCallback onDismissTip;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (draft.photos.isEmpty && !evidenceTipDismissed)
          EvidenceTipCard(
            onDismiss: onDismissTip,
          ),
        if (draft.photos.isEmpty && !evidenceTipDismissed)
          const SizedBox(height: AppSpacing.md),
        PhotoGrid(
          photos: draft.photos,
          onAddPhoto: onAddPhoto,
          onRemovePhoto: onRemovePhoto,
          maxPhotos: ReportFieldLimits.maxPhotos,
        ),
        if (attemptedStages.contains(ReportStage.evidence) &&
            !draft.hasPhotos) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.reportFlowEvidenceNeedsPhoto,
            style: AppTypography.reportsEvidenceValidationHint(
              Theme.of(context).textTheme,
            ),
          ),
        ],
      ],
    );
  }
}
