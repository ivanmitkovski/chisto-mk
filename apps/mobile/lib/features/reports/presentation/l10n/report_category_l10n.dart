import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

extension ReportCategoryL10n on ReportCategory {
  String localizedTitle(AppLocalizations l10n) {
    switch (this) {
      case ReportCategory.illegalLandfill:
        return l10n.reportCategoryIllegalLandfillTitle;
      case ReportCategory.waterPollution:
        return l10n.reportCategoryWaterPollutionTitle;
      case ReportCategory.airPollution:
        return l10n.reportCategoryAirPollutionTitle;
      case ReportCategory.industrialWaste:
        return l10n.reportCategoryIndustrialWasteTitle;
      case ReportCategory.other:
        return l10n.reportCategoryOtherTitle;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case ReportCategory.illegalLandfill:
        return l10n.reportCategoryIllegalLandfillDescription;
      case ReportCategory.waterPollution:
        return l10n.reportCategoryWaterPollutionDescription;
      case ReportCategory.airPollution:
        return l10n.reportCategoryAirPollutionDescription;
      case ReportCategory.industrialWaste:
        return l10n.reportCategoryIndustrialWasteDescription;
      case ReportCategory.other:
        return l10n.reportCategoryOtherDescription;
    }
  }
}
