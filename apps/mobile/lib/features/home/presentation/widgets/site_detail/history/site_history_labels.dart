import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
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
  final String? actor = entry.actorDisplayName?.trim();
  if (actor != null && actor.isNotEmpty) {
    return context.l10n.siteHistoryByActor(actor);
  }
  return null;
}

enum SiteHistoryTileTone { info, success, warning, neutral }

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
    default:
      return SiteHistoryTileTone.neutral;
  }
}

Color siteHistoryToneColor(SiteHistoryTileTone tone) {
  switch (tone) {
    case SiteHistoryTileTone.success:
      return AppColors.primaryDark;
    case SiteHistoryTileTone.warning:
      return AppColors.accentWarning;
    case SiteHistoryTileTone.info:
      return AppColors.accentInfo;
    case SiteHistoryTileTone.neutral:
      return AppColors.textMuted;
  }
}

IconData siteHistoryEntryIcon(SiteHistoryEntryKind kind) {
  switch (kind) {
    case SiteHistoryEntryKind.siteCreated:
      return Icons.place_outlined;
    case SiteHistoryEntryKind.reportSubmitted:
    case SiteHistoryEntryKind.reportApproved:
    case SiteHistoryEntryKind.reportRejected:
    case SiteHistoryEntryKind.reportMerged:
      return Icons.flag_outlined;
    case SiteHistoryEntryKind.statusChanged:
      return Icons.sync_alt_rounded;
    case SiteHistoryEntryKind.cleanupEventScheduled:
    case SiteHistoryEntryKind.cleanupEventStarted:
    case SiteHistoryEntryKind.cleanupEventCompleted:
    case SiteHistoryEntryKind.cleanupEventCancelled:
      return Icons.eco_outlined;
    case SiteHistoryEntryKind.archivedByAdmin:
    case SiteHistoryEntryKind.unarchivedByAdmin:
      return Icons.archive_outlined;
    case SiteHistoryEntryKind.adminNote:
      return Icons.sticky_note_2_outlined;
    case SiteHistoryEntryKind.unknown:
      return Icons.history_rounded;
  }
}

String siteHistoryRelativeTime(BuildContext context, DateTime value) {
  final AppLocalizations l10n = context.l10n;
  final DateTime now = DateTime.now();
  final DateTime safe = value.isAfter(now) ? now : value;
  final Duration diff = now.difference(safe);
  if (diff.inMinutes < 1) return l10n.siteHistoryTimeNow;
  if (diff.inHours < 1) {
    return l10n.siteHistoryTimeMinutes(diff.inMinutes);
  }
  if (diff.inDays < 1) {
    return l10n.siteHistoryTimeHours(diff.inHours);
  }
  if (diff.inDays < 7) {
    return l10n.siteHistoryTimeDays(diff.inDays);
  }
  return siteHistoryAbsoluteDate(context, safe);
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
  if (entry.note != null &&
      entry.note!.trim().isNotEmpty &&
      !canOpenEvent) {
    parts.add(
      noteExpanded
          ? context.l10n.siteHistoryEntryShowLess
          : context.l10n.siteHistoryEntryShowMore,
    );
  }
  return parts.join('. ');
}
