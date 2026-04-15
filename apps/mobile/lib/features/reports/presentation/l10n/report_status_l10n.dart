import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_mock_store.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

String reportUiStatusShortLabel(AppLocalizations l10n, ReportStatus status) {
  switch (status) {
    case ReportStatus.underReview:
      return l10n.reportStatusUnderReviewShort;
    case ReportStatus.approved:
      return l10n.reportStatusApprovedShort;
    case ReportStatus.declined:
      return l10n.reportStatusDeclinedShort;
    case ReportStatus.alreadyReported:
      return l10n.reportStatusAlreadyReportedShort;
  }
}

String apiReportStatusShortLabel(AppLocalizations l10n, ApiReportStatus status) {
  switch (status) {
    case ApiReportStatus.new_:
    case ApiReportStatus.inReview:
      return l10n.reportStatusUnderReviewShort;
    case ApiReportStatus.approved:
      return l10n.reportStatusApprovedShort;
    case ApiReportStatus.deleted:
      return l10n.reportStatusDeclinedShort;
  }
}

/// Tokens used when searching list items by status (substring match).
Set<String> apiReportStatusSearchTokens(AppLocalizations l10n, ApiReportStatus status) {
  final Set<String> tokens = <String>{};
  void add(String raw) {
    final String t = raw.trim().toLowerCase();
    if (t.isEmpty) return;
    tokens.add(t);
  }

  add(apiReportStatusShortLabel(l10n, status));
  switch (status) {
    case ApiReportStatus.new_:
      add('new');
    case ApiReportStatus.inReview:
      add('in_review');
      add('in review');
    case ApiReportStatus.approved:
      add('approved');
    case ApiReportStatus.deleted:
      add('deleted');
      add('declined');
  }
  return tokens;
}

bool apiReportStatusMatchesSearchToken(
  AppLocalizations l10n,
  ApiReportStatus status,
  String token,
) {
  for (final String phrase in apiReportStatusSearchTokens(l10n, status)) {
    if (phrase.contains(token)) return true;
  }
  return false;
}
