import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';

extension CleanupEffortL10n on CleanupEffort {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case CleanupEffort.oneToTwo:
        return l10n.reportCleanupEffortOneToTwo;
      case CleanupEffort.threeToFive:
        return l10n.reportCleanupEffortThreeToFive;
      case CleanupEffort.sixToTen:
        return l10n.reportCleanupEffortSixToTen;
      case CleanupEffort.tenPlus:
        return l10n.reportCleanupEffortTenPlus;
      case CleanupEffort.notSure:
        return l10n.reportCleanupEffortNotSure;
    }
  }
}
