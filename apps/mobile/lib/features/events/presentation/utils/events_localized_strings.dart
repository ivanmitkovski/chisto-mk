import 'package:intl/intl.dart' hide TextDirection;

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Formats a [DateTime] as locale-aware `HH:mm` (24h). Ensures `.toLocal()`
/// so UTC timestamps from the API never leak raw UTC hours into the UI.
String formatCheckInTime(DateTime dt) {
  final DateTime local = dt.toLocal();
  return DateFormat.Hm().format(local);
}

String eventsCountdownLabel(AppLocalizations l10n, DateTime start) {
  final Duration diff = start.difference(DateTime.now());
  if (diff.isNegative) {
    return l10n.eventsCountdownStarted;
  }
  if (diff.inDays > 0) {
    return l10n.eventsCountdownDaysHours(diff.inDays, diff.inHours % 24);
  }
  if (diff.inHours > 0) {
    return l10n.eventsCountdownHoursMinutes(diff.inHours, diff.inMinutes % 60);
  }
  final int minutes = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
  return l10n.eventsCountdownMinutes(minutes);
}

extension EcoEventStatusLocalized on EcoEventStatus {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case EcoEventStatus.upcoming:
        return l10n.eventsStatusUpcoming;
      case EcoEventStatus.inProgress:
        return l10n.eventsStatusInProgress;
      case EcoEventStatus.completed:
        return l10n.eventsStatusCompleted;
      case EcoEventStatus.cancelled:
        return l10n.eventsStatusCancelled;
    }
  }
}

extension EcoEventCategoryLocalized on EcoEventCategory {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case EcoEventCategory.generalCleanup:
        return l10n.eventsCategoryGeneralCleanup;
      case EcoEventCategory.riverAndLake:
        return l10n.eventsCategoryRiverAndLake;
      case EcoEventCategory.treeAndGreen:
        return l10n.eventsCategoryTreeAndGreen;
      case EcoEventCategory.recyclingDrive:
        return l10n.eventsCategoryRecyclingDrive;
      case EcoEventCategory.hazardousRemoval:
        return l10n.eventsCategoryHazardousRemoval;
      case EcoEventCategory.awarenessAndEducation:
        return l10n.eventsCategoryAwarenessAndEducation;
      case EcoEventCategory.other:
        return l10n.eventsCategoryOther;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case EcoEventCategory.generalCleanup:
        return l10n.eventsCategoryGeneralCleanupDescription;
      case EcoEventCategory.riverAndLake:
        return l10n.eventsCategoryRiverAndLakeDescription;
      case EcoEventCategory.treeAndGreen:
        return l10n.eventsCategoryTreeAndGreenDescription;
      case EcoEventCategory.recyclingDrive:
        return l10n.eventsCategoryRecyclingDriveDescription;
      case EcoEventCategory.hazardousRemoval:
        return l10n.eventsCategoryHazardousRemovalDescription;
      case EcoEventCategory.awarenessAndEducation:
        return l10n.eventsCategoryAwarenessAndEducationDescription;
      case EcoEventCategory.other:
        return l10n.eventsCategoryOtherDescription;
    }
  }
}

extension EventGearLocalized on EventGear {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case EventGear.trashBags:
        return l10n.eventsGearTrashBags;
      case EventGear.gloves:
        return l10n.eventsGearGloves;
      case EventGear.rakes:
        return l10n.eventsGearRakes;
      case EventGear.wheelbarrow:
        return l10n.eventsGearWheelbarrow;
      case EventGear.waterBoots:
        return l10n.eventsGearWaterBoots;
      case EventGear.safetyVest:
        return l10n.eventsGearSafetyVest;
      case EventGear.firstAid:
        return l10n.eventsGearFirstAid;
      case EventGear.sunscreen:
        return l10n.eventsGearSunscreen;
    }
  }
}

extension CleanupScaleLocalized on CleanupScale {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case CleanupScale.small:
        return l10n.eventsScaleSmall;
      case CleanupScale.medium:
        return l10n.eventsScaleMedium;
      case CleanupScale.large:
        return l10n.eventsScaleLarge;
      case CleanupScale.massive:
        return l10n.eventsScaleMassive;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case CleanupScale.small:
        return l10n.eventsScaleSmallDescription;
      case CleanupScale.medium:
        return l10n.eventsScaleMediumDescription;
      case CleanupScale.large:
        return l10n.eventsScaleLargeDescription;
      case CleanupScale.massive:
        return l10n.eventsScaleMassiveDescription;
    }
  }
}

extension EventDifficultyLocalized on EventDifficulty {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case EventDifficulty.easy:
        return l10n.eventsDifficultyEasy;
      case EventDifficulty.moderate:
        return l10n.eventsDifficultyModerate;
      case EventDifficulty.hard:
        return l10n.eventsDifficultyHard;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case EventDifficulty.easy:
        return l10n.eventsDifficultyEasyDescription;
      case EventDifficulty.moderate:
        return l10n.eventsDifficultyModerateDescription;
      case EventDifficulty.hard:
        return l10n.eventsDifficultyHardDescription;
    }
  }
}
