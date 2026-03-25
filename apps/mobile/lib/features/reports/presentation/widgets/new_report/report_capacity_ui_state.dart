import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:flutter/material.dart';

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

ReportCapacityUiState mapReportCapacityToUiState(ReportCapacity capacity) {
  final int credits = capacity.creditsAvailable;
  if (credits > 2) {
    return ReportCapacityUiState(
      kind: ReportCapacityUiKind.healthy,
      pillLabel: '$credits reports available',
      pillTone: ReportSurfaceTone.success,
      pillIcon: Icons.eco_outlined,
      bannerTitle: 'Reporting capacity',
      bannerMessage: 'You have $credits report credits available right now.',
      bannerTone: ReportSurfaceTone.success,
      bannerIcon: Icons.eco_outlined,
      reviewMessage: 'This submission will use 1 report credit.',
    );
  }
  if (credits > 0) {
    return ReportCapacityUiState(
      kind: ReportCapacityUiKind.low,
      pillLabel: '$credits report${credits == 1 ? '' : 's'} left',
      pillTone: ReportSurfaceTone.warning,
      pillIcon: Icons.bolt_rounded,
      bannerTitle: 'Low report credits',
      bannerMessage: 'You are running low. ${capacity.unlockHint}',
      bannerTone: ReportSurfaceTone.warning,
      bannerIcon: Icons.bolt_rounded,
      reviewMessage:
          'This submission will use 1 report credit. ${capacity.unlockHint}',
    );
  }
  if (capacity.emergencyAvailable) {
    return ReportCapacityUiState(
      kind: ReportCapacityUiKind.emergency,
      pillLabel: 'Emergency report available',
      pillTone: ReportSurfaceTone.warning,
      pillIcon: Icons.warning_amber_rounded,
      bannerTitle: 'Emergency allowance ready',
      bannerMessage:
          'You can submit one emergency report now. ${capacity.unlockHint}',
      bannerTone: ReportSurfaceTone.warning,
      bannerIcon: Icons.warning_amber_rounded,
      reviewMessage:
          'This submission uses your emergency report allowance. ${capacity.unlockHint}',
    );
  }
  final int? retryAfterSeconds = capacity.retryAfterSeconds;
  final String retryHint = retryAfterSeconds != null && retryAfterSeconds > 0
      ? 'Try again in about ${_cooldownText(retryAfterSeconds)}.'
      : 'Your next emergency report is still cooling down.';
  return ReportCapacityUiState(
    kind: ReportCapacityUiKind.cooldown,
    pillLabel: 'Reporting cooldown active',
    pillTone: ReportSurfaceTone.danger,
    pillIcon: Icons.timer_off_rounded,
    bannerTitle: 'Reporting cooldown',
    bannerMessage: '$retryHint ${capacity.unlockHint}',
    bannerTone: ReportSurfaceTone.danger,
    bannerIcon: Icons.timer_off_rounded,
    reviewMessage: '$retryHint ${capacity.unlockHint}',
  );
}

String _cooldownText(int retryAfterSeconds) {
  if (retryAfterSeconds < 60) {
    return '${retryAfterSeconds}s';
  }
  final int minutes = (retryAfterSeconds / 60).ceil();
  if (minutes < 60) {
    return '${minutes}m';
  }
  final int hours = (minutes / 60).ceil();
  return '${hours}h';
}
