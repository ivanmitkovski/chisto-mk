import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String notificationRelativeTime(AppLocalizations l10n, DateTime value) {
  final Duration diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return l10n.notificationsTimeNow;
  if (diff.inMinutes < 60) {
    return l10n.notificationsTimeMinutes(diff.inMinutes);
  }
  if (diff.inHours < 24) return l10n.notificationsTimeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.notificationsTimeDays(diff.inDays);
  return DateFormat('dd.MM', l10n.localeName).format(value);
}

String notificationDayTitle(
  AppLocalizations l10n,
  DateTime value, {
  DateTime? now,
}) {
  final DateTime refNow = now ?? DateTime.now();
  final DateTime today = DateTime(refNow.year, refNow.month, refNow.day);
  final DateTime input = DateTime(value.year, value.month, value.day);
  final int diff = today.difference(input).inDays;
  if (diff == 0) return l10n.notificationsDayToday;
  if (diff == 1) return l10n.notificationsDayYesterday;
  if (diff < 7) {
    return DateFormat('EEEE', l10n.localeName).format(value);
  }
  return DateFormat('dd.MM.yyyy', l10n.localeName).format(value);
}

String notificationGroupSummary(
  AppLocalizations l10n, {
  required List<String> actorNames,
  required int totalCount,
}) {
  final List<String> names = actorNames
      .where((String n) => n.trim().isNotEmpty)
      .toList();
  if (names.isEmpty) {
    return l10n.notificationsGroupSummaryGeneric(totalCount);
  }
  if (names.length == 1) {
    return l10n.notificationsGroupSummaryOne(names.first);
  }
  if (names.length == 2 && totalCount <= 2) {
    return l10n.notificationsGroupSummaryTwo(names[0], names[1]);
  }
  final int others = (totalCount - 2).clamp(0, 999);
  if (others <= 0) {
    return l10n.notificationsGroupSummaryTwo(names[0], names[1]);
  }
  return l10n.notificationsGroupSummaryMany(names[0], names[1], others);
}
