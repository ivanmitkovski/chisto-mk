import 'package:flutter/material.dart';

import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Localized title for a points history [reasonCode].
String pointsHistoryReasonTitle(AppLocalizations l10n, String code) {
  switch (code) {
    case 'FIRST_REPORT':
      return l10n.profilePointsReasonFirstReport;
    case 'REPORT_APPROVED':
      return l10n.profilePointsReasonReportApproved;
    case 'REPORT_APPROVAL_REVOKED':
      return l10n.profilePointsReasonReportApprovalRevoked;
    case 'REPORT_SUBMITTED':
      return l10n.profilePointsReasonReportSubmitted;
    case 'ECO_ACTION_APPROVED':
      return l10n.profilePointsReasonEcoApproved;
    case 'ECO_ACTION_REALIZED':
      return l10n.profilePointsReasonEcoRealized;
    case 'EVENT_ORGANIZER_APPROVED':
      return l10n.profilePointsReasonEventOrganizerApproved;
    case 'EVENT_JOINED':
      return l10n.profilePointsReasonEventJoined;
    case 'EVENT_JOIN_NO_SHOW':
      return l10n.profilePointsReasonEventJoinNoShow;
    case 'EVENT_CHECK_IN':
      return l10n.profilePointsReasonEventCheckIn;
    case 'EVENT_COMPLETED':
      return l10n.profilePointsReasonEventCompleted;
    default:
      return l10n.profilePointsReasonOther;
  }
}

/// Icon for a points history [reasonCode].
IconData pointsHistoryReasonIcon(String code) {
  switch (code) {
    case 'FIRST_REPORT':
      return Icons.assignment_turned_in_outlined;
    case 'REPORT_APPROVED':
      return Icons.verified_outlined;
    case 'REPORT_APPROVAL_REVOKED':
      return Icons.undo_rounded;
    case 'REPORT_SUBMITTED':
      return Icons.outbox_outlined;
    case 'ECO_ACTION_APPROVED':
    case 'ECO_ACTION_REALIZED':
      return Icons.volunteer_activism_outlined;
    case 'EVENT_ORGANIZER_APPROVED':
      return Icons.verified_outlined;
    case 'EVENT_JOINED':
      return Icons.event_available_outlined;
    case 'EVENT_JOIN_NO_SHOW':
      return Icons.event_busy_outlined;
    case 'EVENT_CHECK_IN':
      return Icons.qr_code_scanner_outlined;
    case 'EVENT_COMPLETED':
      return Icons.flag_outlined;
    default:
      return Icons.stars_rounded;
  }
}

/// Localized signed delta label (+N / −N).
String pointsHistoryDeltaLabel(AppLocalizations l10n, int delta) {
  if (delta >= 0) {
    return l10n.profilePointsDeltaPositive(delta);
  }
  return l10n.profilePointsDeltaNegative(delta);
}
