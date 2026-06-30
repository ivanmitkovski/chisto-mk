import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Calendar day for event UI (list, detail, share, reminders) using [Localizations.localeOf].
String formatEventCalendarDate(BuildContext context, DateTime date) {
  final String tag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('MMM d, y', tag).format(date);
}
