import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

const String mapStatusReported = 'REPORTED';
const String mapStatusVerified = 'VERIFIED';
const String mapStatusCleanupScheduled = 'CLEANUP_SCHEDULED';
const String mapStatusInProgress = 'IN_PROGRESS';
const String mapStatusCleaned = 'CLEANED';
const String mapStatusDisputed = 'DISPUTED';
const String mapStatusArchived = 'ARCHIVED';
const String mapStatusUnknown = 'UNKNOWN';

const List<String> mapStatusOrder = <String>[
  mapStatusReported,
  mapStatusVerified,
  mapStatusCleanupScheduled,
  mapStatusInProgress,
  mapStatusCleaned,
  mapStatusDisputed,
  mapStatusArchived,
];

/// Workflow statuses shown as map filter chips. Archived visibility uses
/// [MapFilterState.includeArchived] instead of a status chip.
const List<String> mapFilterStatusOrder = <String>[
  mapStatusReported,
  mapStatusVerified,
  mapStatusCleanupScheduled,
  mapStatusInProgress,
  mapStatusCleaned,
  mapStatusDisputed,
];

Set<String> get mapFilterDefaultStatuses =>
    mapFilterStatusOrder.map(mapStatusCodeFromUnknown).toSet();

String mapStatusDisplay(AppLocalizations l10n, String statusCode) {
  switch (statusCode) {
    case mapStatusReported:
      return l10n.mapFilterSiteStatusReported;
    case mapStatusVerified:
      return l10n.mapFilterSiteStatusVerified;
    case mapStatusCleanupScheduled:
      return l10n.mapFilterSiteStatusCleanupScheduled;
    case mapStatusInProgress:
      return l10n.mapFilterSiteStatusInProgress;
    case mapStatusCleaned:
      return l10n.mapFilterSiteStatusCleaned;
    case mapStatusDisputed:
      return l10n.mapFilterSiteStatusDisputed;
    case mapStatusArchived:
      return l10n.mapFilterSiteStatusArchived;
    default:
      return l10n.mapFilterSiteStatusUnknown;
  }
}

Color mapStatusColor(String statusCode) {
  switch (statusCode) {
    case mapStatusReported:
      return AppColors.accentWarning;
    case mapStatusVerified:
      return AppColors.primary;
    case mapStatusCleanupScheduled:
    case mapStatusInProgress:
      return AppColors.accentInfo;
    case mapStatusCleaned:
      return AppColors.primaryDark;
    case mapStatusDisputed:
      return AppColors.error;
    case mapStatusArchived:
      return AppColors.textMuted;
    default:
      return AppColors.textMuted;
  }
}

String mapStatusCodeFromUnknown(String? raw) {
  final String normalized = (raw ?? '').trim().toUpperCase();
  switch (normalized) {
    case mapStatusReported:
      return mapStatusReported;
    case mapStatusVerified:
      return mapStatusVerified;
    case mapStatusCleanupScheduled:
    case 'CLEANUP SCHEDULED':
      return mapStatusCleanupScheduled;
    case mapStatusInProgress:
    case 'IN PROGRESS':
      return mapStatusInProgress;
    case mapStatusCleaned:
      return mapStatusCleaned;
    case mapStatusDisputed:
      return mapStatusDisputed;
    case mapStatusArchived:
      return mapStatusArchived;
    default:
      return mapStatusUnknown;
  }
}
