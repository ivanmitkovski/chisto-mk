import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_retry_duration.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReportCapacityUiKind { healthy, low, emergency, cooldown }

class ReportCapacityUiState {
  const ReportCapacityUiState({
    required this.kind,
    required this.pillLabel,
    required this.pillTone,
    required this.pillIcon,
    required this.bannerTitle,
    required this.bannerMessage,
    required this.bannerTone,
    required this.bannerIcon,
    required this.reviewMessage,
  });

  final ReportCapacityUiKind kind;
  final String pillLabel;
  final ReportSurfaceTone pillTone;
  final IconData pillIcon;
  final String bannerTitle;
  final String bannerMessage;
  final ReportSurfaceTone bannerTone;
  final IconData bannerIcon;
  final String reviewMessage;
}

ReportCapacityUiState mapReportCapacityToUiState(
  ReportCapacity capacity, {
  required AppLocalizations l10n,
  /// Localized date/time phrase when emergency unlocks (e.g. from [DateFormat]); overrides generic retry text in cooldown.
  String? nextEmergencyAvailableDescription,
}) {
  final String unlockHint = l10n.reportCapacityUnlockHint;
  final int credits = capacity.creditsAvailable;
  if (credits > 2) {
    return ReportCapacityUiState(
      kind: ReportCapacityUiKind.healthy,
      pillLabel: l10n.reportCapacityPillHealthy(credits),
      pillTone: ReportSurfaceTone.success,
      pillIcon: Icons.assignment_outlined,
      bannerTitle: l10n.reportCapacityBannerHealthyTitle,
      bannerMessage: l10n.reportCapacityBannerHealthyBody(credits),
      bannerTone: ReportSurfaceTone.success,
      bannerIcon: Icons.assignment_outlined,
      reviewMessage: l10n.reportCapacityReviewHealthy,
    );
  }
  if (credits > 0) {
    return ReportCapacityUiState(
      kind: ReportCapacityUiKind.low,
      pillLabel: l10n.reportCapacityPillLow(credits),
      pillTone: ReportSurfaceTone.warning,
      pillIcon: Icons.bolt_rounded,
      bannerTitle: l10n.reportCapacityBannerLowTitle,
      bannerMessage: l10n.reportCapacityBannerLowBody(unlockHint),
      bannerTone: ReportSurfaceTone.warning,
      bannerIcon: Icons.bolt_rounded,
      reviewMessage: l10n.reportCapacityReviewLow(unlockHint),
    );
  }
  if (capacity.emergencyAvailable) {
    return ReportCapacityUiState(
      kind: ReportCapacityUiKind.emergency,
      pillLabel: l10n.reportCapacityPillEmergency,
      pillTone: ReportSurfaceTone.warning,
      pillIcon: Icons.warning_amber_rounded,
      bannerTitle: l10n.reportCapacityBannerEmergencyTitle,
      bannerMessage:
          l10n.reportCapacityBannerEmergencyBody(unlockHint),
      bannerTone: ReportSurfaceTone.warning,
      bannerIcon: Icons.warning_amber_rounded,
      reviewMessage: l10n.reportCapacityReviewEmergency(unlockHint),
    );
  }
  final int? retryAfterSeconds = capacity.retryAfterSeconds;
  final String? trimmedNext = nextEmergencyAvailableDescription?.trim();
  final String retryLine = trimmedNext != null && trimmedNext.isNotEmpty
      ? l10n.reportCapacityCooldownRetryOnDate(trimmedNext)
      : retryAfterSeconds != null && retryAfterSeconds > 0
          ? l10n.reportCapacityCooldownTryAgainInAbout(
              formatReportCapacityRetryDuration(l10n, retryAfterSeconds),
            )
          : l10n.reportCapacityCooldownStillWaiting;
  return ReportCapacityUiState(
    kind: ReportCapacityUiKind.cooldown,
    pillLabel: l10n.reportCapacityPillCooldown,
    pillTone: ReportSurfaceTone.danger,
    pillIcon: Icons.timer_off_rounded,
    bannerTitle: l10n.reportCapacityBannerCooldownTitle,
    bannerMessage: l10n.reportCapacityBannerCooldownBody(
      retryLine,
      unlockHint,
    ),
    bannerTone: ReportSurfaceTone.danger,
    bannerIcon: Icons.timer_off_rounded,
    reviewMessage: l10n.reportCapacityReviewCooldown(
      retryLine,
      unlockHint,
    ),
  );
}

/// Formats [utc] in the device locale for cooldown copy (expects API UTC instant).
String? formatNextEmergencyUnlockLocal(BuildContext context, DateTime? utc) {
  if (utc == null) return null;
  final String localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMMMEd(localeName).add_jm().format(utc.toLocal());
}
