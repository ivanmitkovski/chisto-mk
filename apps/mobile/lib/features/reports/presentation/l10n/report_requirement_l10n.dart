import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

extension ReportRequirementL10n on ReportRequirement {
  String label(AppLocalizations l10n) {
    switch (this) {
      case ReportRequirement.photos:
        return l10n.reportRequirementPhotos;
      case ReportRequirement.category:
        return l10n.reportRequirementCategory;
      case ReportRequirement.title:
        return l10n.reportRequirementTitle;
      case ReportRequirement.location:
        return l10n.reportRequirementLocation;
    }
  }
}
