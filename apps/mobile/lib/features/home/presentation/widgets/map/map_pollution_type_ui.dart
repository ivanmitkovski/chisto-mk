import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

String mapPollutionTypeDisplay(AppLocalizations l10n, String rawType) {
  switch (reportPollutionTypeCodeFromUnknown(rawType)) {
    case 'ILLEGAL_LANDFILL':
      return l10n.reportCategoryIllegalLandfillTitle;
    case 'WATER_POLLUTION':
      return l10n.reportCategoryWaterPollutionTitle;
    case 'AIR_POLLUTION':
      return l10n.reportCategoryAirPollutionTitle;
    case 'INDUSTRIAL_WASTE':
      return l10n.reportCategoryIndustrialWasteTitle;
    case 'OTHER':
      return l10n.reportCategoryOtherTitle;
    default:
      return l10n.mapFilterPollutionTypeUnknown;
  }
}
