import 'package:chisto_mobile/features/home/domain/models/site_report_reason.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

extension SiteReportReasonL10n on SiteReportReason {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case SiteReportReason.fakeData:
        return l10n.siteReportReasonFakeLabel;
      case SiteReportReason.alreadyReported:
        return l10n.siteReportReasonResolvedLabel;
      case SiteReportReason.wrongLocation:
        return l10n.siteReportReasonWrongLocationLabel;
      case SiteReportReason.duplicate:
        return l10n.siteReportReasonDuplicateLabel;
      case SiteReportReason.spam:
        return l10n.siteReportReasonSpamLabel;
      case SiteReportReason.other:
        return l10n.siteReportReasonOtherLabel;
    }
  }

  String localizedSubtitle(AppLocalizations l10n) {
    switch (this) {
      case SiteReportReason.fakeData:
        return l10n.siteReportReasonFakeSubtitle;
      case SiteReportReason.alreadyReported:
        return l10n.siteReportReasonResolvedSubtitle;
      case SiteReportReason.wrongLocation:
        return l10n.siteReportReasonWrongLocationSubtitle;
      case SiteReportReason.duplicate:
        return l10n.siteReportReasonDuplicateSubtitle;
      case SiteReportReason.spam:
        return l10n.siteReportReasonSpamSubtitle;
      case SiteReportReason.other:
        return l10n.siteReportReasonOtherSubtitle;
    }
  }
}
