import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

const RelativeTimeFormatter _commentMetaRelativeTimeFormatter =
    RelativeTimeFormatter(RelativeTimeFormatOptions.commentMeta);

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
  final int likes = likeCount ?? 0;
  final String time = _commentMetaRelativeTimeFormatter.format(
    _CommentMetaRelativeTimeLabels(l10n),
    createdAt,
    now,
  );
  if (likes <= 0) {
    return time;
  }
  final Duration diff = now.difference(createdAt);
  if (diff.isNegative || diff.inMinutes < 1) {
    return l10n.commentsCommentMetaJustNowWithLikes(likes);
  }
  if (diff.inHours < 1) {
    return l10n.commentsCommentMetaMinutesAgoWithLikes(
      diff.inMinutes.clamp(1, 59),
      likes,
    );
  }
  if (diff.inHours < 24) {
    return l10n.commentsCommentMetaHoursAgoWithLikes(
      diff.inHours.clamp(1, 23),
      likes,
    );
  }
  if (diff.inDays < 7) {
    return l10n.commentsCommentMetaDaysAgoWithLikes(
      diff.inDays.clamp(1, 6),
      likes,
    );
  }
  return l10n.commentsCommentMetaDateWithLikes(time, likes);
}

class _CommentMetaRelativeTimeLabels implements RelativeTimeLabels {
  _CommentMetaRelativeTimeLabels(this.l10n);

  final AppLocalizations l10n;

  @override
  String get justNow => l10n.commentsCommentMetaJustNow;

  @override
  String minutes(int count) => l10n.commentsCommentMetaMinutesAgo(count);

  @override
  String hours(int count) => l10n.commentsCommentMetaHoursAgo(count);

  @override
  String days(int count) => l10n.commentsCommentMetaDaysAgo(count);

  @override
  String weeks(int count) => days(count);

  @override
  String shortCalendarDate(DateTime local) => longCalendarDate(local);

  @override
  String longCalendarDate(DateTime local) =>
      DateFormat.yMMMd(l10n.localeName).format(local);
}
