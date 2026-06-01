import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum SiteHistorySectionBucket { today, yesterday, thisWeek, earlierMonth }

class SiteHistorySection {
  const SiteHistorySection({
    required this.bucket,
    required this.entries,
    this.anchorDate,
  });

  final SiteHistorySectionBucket bucket;
  final DateTime? anchorDate;
  final List<SiteHistoryEntry> entries;
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

SiteHistorySectionBucket _bucketFor(DateTime occurredAt, DateTime now) {
  final DateTime safe = occurredAt.isAfter(now) ? now : occurredAt;
  final DateTime day = _startOfDay(safe);
  final DateTime today = _startOfDay(now);
  if (day == today) {
    return SiteHistorySectionBucket.today;
  }
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  if (day == yesterday) {
    return SiteHistorySectionBucket.yesterday;
  }
  final int weekday = now.weekday;
  final DateTime weekStart = today.subtract(Duration(days: weekday - 1));
  if (!day.isBefore(weekStart)) {
    return SiteHistorySectionBucket.thisWeek;
  }
  return SiteHistorySectionBucket.earlierMonth;
}

DateTime? _anchorForBucket(
  SiteHistorySectionBucket bucket,
  DateTime occurredAt,
) {
  if (bucket != SiteHistorySectionBucket.earlierMonth) {
    return null;
  }
  return DateTime(occurredAt.year, occurredAt.month);
}

bool _sameSection(
  SiteHistorySectionBucket bucket,
  DateTime? anchor,
  SiteHistorySectionBucket otherBucket,
  DateTime? otherAnchor,
) {
  if (bucket != otherBucket) return false;
  if (bucket != SiteHistorySectionBucket.earlierMonth) return true;
  return anchor?.year == otherAnchor?.year &&
      anchor?.month == otherAnchor?.month;
}

/// Groups [items] (newest-first) into stable chronological sections.
List<SiteHistorySection> groupSiteHistoryByBucket(
  List<SiteHistoryEntry> items,
  DateTime now,
) {
  if (items.isEmpty) return const <SiteHistorySection>[];

  final List<SiteHistorySection> sections = <SiteHistorySection>[];
  SiteHistorySectionBucket? currentBucket;
  DateTime? currentAnchor;
  final List<SiteHistoryEntry> currentEntries = <SiteHistoryEntry>[];

  void flush() {
    if (currentEntries.isEmpty || currentBucket == null) return;
    sections.add(
      SiteHistorySection(
        bucket: currentBucket,
        anchorDate: currentAnchor,
        entries: List<SiteHistoryEntry>.from(currentEntries),
      ),
    );
    currentEntries.clear();
  }

  for (final SiteHistoryEntry entry in items) {
    final SiteHistorySectionBucket bucket = _bucketFor(entry.occurredAt, now);
    final DateTime? anchor = _anchorForBucket(bucket, entry.occurredAt);
    if (currentBucket == null ||
        !_sameSection(currentBucket, currentAnchor, bucket, anchor)) {
      flush();
      currentBucket = bucket;
      currentAnchor = anchor;
    }
    currentEntries.add(entry);
  }
  flush();
  return sections;
}

String siteHistorySectionLabel(
  BuildContext context,
  SiteHistorySection section,
) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  switch (section.bucket) {
    case SiteHistorySectionBucket.today:
      return l10n.siteHistorySectionToday;
    case SiteHistorySectionBucket.yesterday:
      return l10n.siteHistorySectionYesterday;
    case SiteHistorySectionBucket.thisWeek:
      return l10n.siteHistorySectionThisWeek;
    case SiteHistorySectionBucket.earlierMonth:
      final DateTime anchor = section.anchorDate ?? DateTime.now();
      final String month = DateFormat.MMMM(
        Localizations.localeOf(context).toString(),
      ).format(anchor);
      return l10n.siteHistorySectionMonth(month, anchor.year);
  }
}
