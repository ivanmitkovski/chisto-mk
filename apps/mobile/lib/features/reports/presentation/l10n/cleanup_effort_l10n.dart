import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

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
