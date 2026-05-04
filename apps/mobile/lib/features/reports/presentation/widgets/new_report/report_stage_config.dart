import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_help.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Single source of truth for step copy, requirements, and help sections (backed by ARB).
class ReportStageConfig {
  const ReportStageConfig({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.shortLabel,
    required this.primaryActionLabel,
    required this.primaryRequirementLabel,
    this.secondaryRequirementLabel,
    required this.infoTitle,
    required this.helpSections,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String shortLabel;
  final String primaryActionLabel;
  final String primaryRequirementLabel;
  final String? secondaryRequirementLabel;
  final String infoTitle;
  final List<StageHelpSection> helpSections;

  static ReportStageConfig resolve(ReportStage stage, AppLocalizations l10n) {
    switch (stage) {
      case ReportStage.evidence:
        return ReportStageConfig(
          eyebrow: l10n.reportStageEvidenceEyebrow,
          title: l10n.reportStageEvidenceTitle,
          subtitle: l10n.reportStageEvidenceSubtitle,
          shortLabel: l10n.reportStageEvidenceShortLabel,
          primaryActionLabel: l10n.reportStageEvidencePrimaryAction,
          primaryRequirementLabel: l10n.reportStageEvidencePrimaryRequirement,
          secondaryRequirementLabel:
              l10n.reportStageEvidenceSecondaryRequirement,
          infoTitle: l10n.reportStageEvidenceInfoTitle,
          helpSections: <StageHelpSection>[
            StageHelpSection(
              title: l10n.reportHelpEvidenceS0Title,
              body: l10n.reportHelpEvidenceS0Body,
            ),
            StageHelpSection(
              title: l10n.reportHelpEvidenceS1Title,
              body: l10n.reportHelpEvidenceS1Body,
            ),
          ],
        );
      case ReportStage.details:
        return ReportStageConfig(
          eyebrow: l10n.reportStageDetailsEyebrow,
          title: l10n.reportStageDetailsTitle,
          subtitle: l10n.reportStageDetailsSubtitle,
          shortLabel: l10n.reportStageDetailsShortLabel,
          primaryActionLabel: l10n.reportStageDetailsPrimaryAction,
          primaryRequirementLabel: l10n.reportStageDetailsPrimaryRequirement,
          secondaryRequirementLabel:
              l10n.reportStageDetailsSecondaryRequirement,
          infoTitle: l10n.reportStageDetailsInfoTitle,
          helpSections: <StageHelpSection>[
            StageHelpSection(
              title: l10n.reportHelpDetailsS0Title,
              body: l10n.reportHelpDetailsS0Body,
            ),
            StageHelpSection(
              title: l10n.reportHelpDetailsS1Title,
              body: l10n.reportHelpDetailsS1Body,
            ),
          ],
        );
      case ReportStage.location:
        return ReportStageConfig(
          eyebrow: l10n.reportStageLocationEyebrow,
          title: l10n.reportStageLocationTitle,
          subtitle: l10n.reportStageLocationSubtitle,
          shortLabel: l10n.reportStageLocationShortLabel,
          primaryActionLabel: l10n.reportStageLocationPrimaryAction,
          primaryRequirementLabel: l10n.reportStageLocationPrimaryRequirement,
          secondaryRequirementLabel:
              l10n.reportStageLocationSecondaryRequirement,
          infoTitle: l10n.reportStageLocationInfoTitle,
          helpSections: <StageHelpSection>[
            StageHelpSection(
              title: l10n.reportHelpLocationS0Title,
              body: l10n.reportHelpLocationS0Body,
            ),
            StageHelpSection(
              title: l10n.reportHelpLocationS1Title,
              body: l10n.reportHelpLocationS1Body,
            ),
            StageHelpSection(
              title: l10n.reportHelpLocationS2Title,
              body: l10n.reportHelpLocationS2Body,
            ),
          ],
        );
      case ReportStage.review:
        return ReportStageConfig(
          eyebrow: l10n.reportStageReviewEyebrow,
          title: l10n.reportStageReviewTitle,
          subtitle: l10n.reportStageReviewSubtitle,
          shortLabel: l10n.reportStageReviewShortLabel,
          primaryActionLabel: l10n.reportStageReviewPrimaryAction,
          primaryRequirementLabel: l10n.reportStageReviewPrimaryRequirement,
          secondaryRequirementLabel: null,
          infoTitle: l10n.reportStageReviewInfoTitle,
          helpSections: <StageHelpSection>[
            StageHelpSection(
              title: l10n.reportHelpReviewS0Title,
              body: l10n.reportHelpReviewS0Body,
            ),
            StageHelpSection(
              title: l10n.reportHelpReviewS1Title,
              body: l10n.reportHelpReviewS1Body,
            ),
          ],
        );
    }
  }
}

extension ReportStageConfigX on ReportStage {
  ReportStageConfig config(AppLocalizations l10n) =>
      ReportStageConfig.resolve(this, l10n);
}
