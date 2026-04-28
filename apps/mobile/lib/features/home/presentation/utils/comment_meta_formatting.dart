import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Builds the muted subtitle under a comment (time + optional likes), full sentences per locale.
String formatCommentMetaSubtitle(
  AppLocalizations l10n,
  DateTime createdAt,
  DateTime now, {
  required bool isDeleting,
  required bool isEditing,
  int? likeCount,
}) {
  if (isDeleting) {
    return l10n.commentsStatusDeleting;
  }
  if (isEditing) {
    return l10n.commentsStatusSavingEdits;
  }
  final Duration diff = now.difference(createdAt);
  final int likes = likeCount ?? 0;
  if (diff.isNegative || diff.inMinutes < 1) {
    return likes > 0
        ? l10n.commentsCommentMetaJustNowWithLikes(likes)
        : l10n.commentsCommentMetaJustNow;
  }
  if (diff.inHours < 1) {
    final int m = diff.inMinutes.clamp(1, 59);
    return likes > 0
        ? l10n.commentsCommentMetaMinutesAgoWithLikes(m, likes)
        : l10n.commentsCommentMetaMinutesAgo(m);
  }
  if (diff.inHours < 24) {
    final int h = diff.inHours.clamp(1, 23);
    return likes > 0
        ? l10n.commentsCommentMetaHoursAgoWithLikes(h, likes)
        : l10n.commentsCommentMetaHoursAgo(h);
  }
  if (diff.inDays < 7) {
    final int d = diff.inDays.clamp(1, 6);
    return likes > 0
        ? l10n.commentsCommentMetaDaysAgoWithLikes(d, likes)
        : l10n.commentsCommentMetaDaysAgo(d);
  }
  final String date = DateFormat.yMMMd(
    l10n.localeName,
  ).format(createdAt.toLocal());
  return likes > 0
      ? l10n.commentsCommentMetaDateWithLikes(date, likes)
      : l10n.commentsCommentMetaDate(date);
}
