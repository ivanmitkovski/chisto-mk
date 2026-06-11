import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:flutter/material.dart';

String siteHistoryEntryTitle(BuildContext context, SiteHistoryEntry entry) {
  final AppLocalizations l10n = context.l10n;
  switch (entry.kind) {
    case SiteHistoryEntryKind.siteCreated:
      return l10n.siteHistoryKindSiteCreated;
    case SiteHistoryEntryKind.reportSubmitted:
      return l10n.siteHistoryKindReportSubmitted;
    case SiteHistoryEntryKind.reportApproved:
      return l10n.siteHistoryKindReportApproved;
    case SiteHistoryEntryKind.reportRejected:
      return l10n.siteHistoryKindReportRejected;
    case SiteHistoryEntryKind.reportMerged:
      return l10n.siteHistoryKindReportMerged;
    case SiteHistoryEntryKind.statusChanged:
      final String? from = entry.fromStatus;
      final String? to = entry.toStatus;
      if (from != null && to != null) {
        return l10n.siteHistoryKindStatusChanged(
          mapStatusDisplay(l10n, mapStatusCodeFromUnknown(from)),
          mapStatusDisplay(l10n, mapStatusCodeFromUnknown(to)),
        );
      }
      return l10n.siteHistoryKindStatusChangedGeneric;
    case SiteHistoryEntryKind.cleanupEventScheduled:
      return l10n.siteHistoryKindCleanupScheduled;
    case SiteHistoryEntryKind.cleanupEventStarted:
      return l10n.siteHistoryKindCleanupStarted;
    case SiteHistoryEntryKind.cleanupEventCompleted:
      return l10n.siteHistoryKindCleanupCompleted;
    case SiteHistoryEntryKind.cleanupEventCancelled:
      return l10n.siteHistoryKindCleanupCancelled;
    case SiteHistoryEntryKind.archivedByAdmin:
      return l10n.siteHistoryKindArchived;
    case SiteHistoryEntryKind.unarchivedByAdmin:
      return l10n.siteHistoryKindUnarchived;
    case SiteHistoryEntryKind.adminNote:
      return l10n.siteHistoryKindAdminNote;
    case SiteHistoryEntryKind.unknown:
      return l10n.siteHistoryKindUnknown;
  }
}

String? siteHistoryEntrySubtitle(BuildContext context, SiteHistoryEntry entry) {
  if (entry.note != null && entry.note!.trim().isNotEmpty) {
    return entry.note!.trim();
  }
  final String? actor = entry.actorIsDeleted
      ? context.l10n.deletedUser
      : entry.actorDisplayName?.trim();
  final bool hasActor = actor != null && actor.isNotEmpty;
  if (!hasActor && !siteHistoryActorIsAdmin(entry.actorRole)) {
    return null;
  }
  if (siteHistoryEntryShowsAdminActor(entry)) {
    return context.l10n.siteHistoryByAdmin;
  }
  if (hasActor) {
    return context.l10n.siteHistoryByActor(actor);
  }
  return null;
}

const Set<String> _siteHistoryAdminRoles = <String>{
  'SUPPORT',
  'ADMIN',
  'SUPER_ADMIN',
};

bool siteHistoryActorIsAdmin(String? role) {
  if (role == null || role.trim().isEmpty) return false;
  return _siteHistoryAdminRoles.contains(role.trim().toUpperCase());
}

bool siteHistoryEntryShowsAdminActor(SiteHistoryEntry entry) {
  if (siteHistoryActorIsAdmin(entry.actorRole)) return true;
  switch (entry.kind) {
    case SiteHistoryEntryKind.reportApproved:
    case SiteHistoryEntryKind.reportRejected:
    case SiteHistoryEntryKind.reportMerged:
    case SiteHistoryEntryKind.archivedByAdmin:
    case SiteHistoryEntryKind.unarchivedByAdmin:
    case SiteHistoryEntryKind.adminNote:
      return true;
    case SiteHistoryEntryKind.statusChanged:
      if (entry.actorIsDeleted) return false;
      final String? actor = entry.actorDisplayName?.trim();
      return actor != null && actor.isNotEmpty;
    case SiteHistoryEntryKind.siteCreated:
    case SiteHistoryEntryKind.reportSubmitted:
    case SiteHistoryEntryKind.cleanupEventScheduled:
    case SiteHistoryEntryKind.cleanupEventStarted:
    case SiteHistoryEntryKind.cleanupEventCompleted:
    case SiteHistoryEntryKind.cleanupEventCancelled:
    case SiteHistoryEntryKind.unknown:
      return false;
  }
}

enum SiteHistoryTileTone { info, success, warning, neutral, accent }

SiteHistoryTileTone siteHistoryEntryTone(SiteHistoryEntryKind kind) {
  switch (kind) {
    case SiteHistoryEntryKind.reportApproved:
    case SiteHistoryEntryKind.cleanupEventCompleted:
    case SiteHistoryEntryKind.unarchivedByAdmin:
      return SiteHistoryTileTone.success;
    case SiteHistoryEntryKind.reportRejected:
    case SiteHistoryEntryKind.archivedByAdmin:
    case SiteHistoryEntryKind.cleanupEventCancelled:
      return SiteHistoryTileTone.warning;
    case SiteHistoryEntryKind.statusChanged:
    case SiteHistoryEntryKind.cleanupEventScheduled:
    case SiteHistoryEntryKind.cleanupEventStarted:
    case SiteHistoryEntryKind.adminNote:
      return SiteHistoryTileTone.info;
    case SiteHistoryEntryKind.siteCreated:
    case SiteHistoryEntryKind.reportSubmitted:
    case SiteHistoryEntryKind.reportMerged:
      return SiteHistoryTileTone.accent;
    case SiteHistoryEntryKind.unknown:
      return SiteHistoryTileTone.neutral;
  }
}

/// Distinct accent for each timeline entry kind — always a saturated brand color.
Color siteHistoryEntryAccentColor(SiteHistoryEntryKind kind) {
  switch (kind) {
    case SiteHistoryEntryKind.siteCreated:
      return AppColors.primary;
    case SiteHistoryEntryKind.reportSubmitted:
      return AppColors.notificationReport;
    case SiteHistoryEntryKind.reportApproved:
      return AppColors.primaryDark;
    case SiteHistoryEntryKind.reportRejected:
      return AppColors.accentDanger;
    case SiteHistoryEntryKind.reportMerged:
      return AppColors.notificationComment;
    case SiteHistoryEntryKind.statusChanged:
      return AppColors.accentInfo;
    case SiteHistoryEntryKind.cleanupEventScheduled:
      return AppColors.accentInfo;
    case SiteHistoryEntryKind.cleanupEventStarted:
      return AppColors.notificationChat;
    case SiteHistoryEntryKind.cleanupEventCompleted:
      return AppColors.primaryDark;
    case SiteHistoryEntryKind.cleanupEventCancelled:
      return AppColors.accentWarningDark;
    case SiteHistoryEntryKind.archivedByAdmin:
      return AppColors.textSecondary;
    case SiteHistoryEntryKind.unarchivedByAdmin:
      return AppColors.primary;
    case SiteHistoryEntryKind.adminNote:
      return AppColors.notificationComment;
    case SiteHistoryEntryKind.unknown:
      return AppColors.textMuted;
  }
}

Color siteHistoryEntryAccentBackground(SiteHistoryEntryKind kind) {
  return siteHistoryEntryAccentColor(kind).withValues(alpha: 0.14);
}

Color siteHistoryEntryAccentBorder(SiteHistoryEntryKind kind) {
  return siteHistoryEntryAccentColor(kind).withValues(alpha: 0.28);
}

Color siteHistoryToneColor(SiteHistoryTileTone tone) {
  switch (tone) {
    case SiteHistoryTileTone.success:
      return AppColors.primaryDark;
    case SiteHistoryTileTone.warning:
      return AppColors.accentWarning;
    case SiteHistoryTileTone.info:
      return AppColors.accentInfo;
    case SiteHistoryTileTone.accent:
      return AppColors.notificationReport;
    case SiteHistoryTileTone.neutral:
      return AppColors.textMuted;
  }
}

Color siteHistoryToneBackgroundColor(SiteHistoryTileTone tone) {
  return siteHistoryToneColor(tone).withValues(alpha: 0.14);
}

IconData siteHistoryEntryIcon(SiteHistoryEntryKind kind) {
  switch (kind) {
    case SiteHistoryEntryKind.siteCreated:
      return Icons.add_location_alt_outlined;
    case SiteHistoryEntryKind.reportSubmitted:
      return Icons.flag_outlined;
    case SiteHistoryEntryKind.reportApproved:
      return Icons.check_circle_outline_rounded;
    case SiteHistoryEntryKind.reportRejected:
      return Icons.do_not_disturb_on_outlined;
    case SiteHistoryEntryKind.reportMerged:
      return Icons.call_merge_rounded;
    case SiteHistoryEntryKind.statusChanged:
      return Icons.sync_alt_rounded;
    case SiteHistoryEntryKind.cleanupEventScheduled:
      return Icons.event_available_outlined;
    case SiteHistoryEntryKind.cleanupEventStarted:
      return Icons.cleaning_services_outlined;
    case SiteHistoryEntryKind.cleanupEventCompleted:
      return Icons.verified_outlined;
    case SiteHistoryEntryKind.cleanupEventCancelled:
      return Icons.event_busy_outlined;
    case SiteHistoryEntryKind.archivedByAdmin:
      return Icons.archive_outlined;
    case SiteHistoryEntryKind.unarchivedByAdmin:
      return Icons.unarchive_outlined;
    case SiteHistoryEntryKind.adminNote:
      return Icons.sticky_note_2_outlined;
    case SiteHistoryEntryKind.unknown:
      return Icons.history_rounded;
  }
}

const RelativeTimeFormatter _siteHistoryRelativeTimeFormatter =
    RelativeTimeFormatter(RelativeTimeFormatOptions.siteHistory);

String siteHistoryRelativeTime(BuildContext context, DateTime value) {
  final AppLocalizations l10n = context.l10n;
  return _siteHistoryRelativeTimeFormatter.format(
    _SiteHistoryRelativeTimeLabels(l10n, context),
    value,
    DateTime.now(),
  );
}

class _SiteHistoryRelativeTimeLabels implements RelativeTimeLabels {
  _SiteHistoryRelativeTimeLabels(this.l10n, this.context);

  final AppLocalizations l10n;
  final BuildContext context;

  @override
  String get justNow => l10n.siteHistoryTimeNow;

  @override
  String minutes(int count) => l10n.siteHistoryTimeMinutes(count);

  @override
  String hours(int count) => l10n.siteHistoryTimeHours(count);

  @override
  String days(int count) => l10n.siteHistoryTimeDays(count);

  @override
  String weeks(int count) => days(count);

  @override
  String shortCalendarDate(DateTime local) => longCalendarDate(local);

  @override
  String longCalendarDate(DateTime local) =>
      siteHistoryAbsoluteDate(context, local);
}

String siteHistoryAbsoluteDate(BuildContext context, DateTime value) {
  return MaterialLocalizations.of(context).formatMediumDate(value);
}

String siteHistoryComposeSemanticLabel(
  BuildContext context,
  SiteHistoryEntry entry, {
  required String relativeTime,
  String? subtitle,
  required bool canOpenEvent,
  required bool noteExpanded,
}) {
  final String title = siteHistoryEntryTitle(context, entry);
  final List<String> parts = <String>[title, relativeTime];
  if (subtitle != null && subtitle.isNotEmpty) {
    parts.add(subtitle);
  }
  if (canOpenEvent) {
    parts.add(context.l10n.siteHistoryEntryOpenEvent);
  }
  if (entry.note != null && entry.note!.trim().isNotEmpty && !canOpenEvent) {
    parts.add(
      noteExpanded
          ? context.l10n.siteHistoryEntryShowLess
          : context.l10n.siteHistoryEntryShowMore,
    );
  }
  return parts.join('. ');
}
