import 'package:flutter/widgets.dart';

/// Whether [text] fits on one line within [maxWidth] using [style].
bool lineFitsWidth(
  String text,
  TextStyle style,
  double maxWidth,
  TextDirection direction,
  TextScaler textScaler,
) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    maxLines: 1,
    textScaler: textScaler,
  )..layout(minWidth: 0, maxWidth: maxWidth);
  return !painter.didExceedMaxLines;
}

/// Ellipsizes [raw] to fit [maxWidth] when laid out as a single line with [style].
/// Prefers dropping trailing whole words before appending […]. If a single word
/// is wider than the budget, trims grapheme clusters from the end until it fits.
String ellipsizeWordsToMaxWidth(
  String raw,
  TextStyle style,
  double maxWidth,
  TextDirection direction,
  TextScaler textScaler,
) {
  final String text = raw.trim();
  if (text.isEmpty || maxWidth <= 0) {
    return text;
  }
  const String ellipsis = '…';
  bool fits(String candidate) => lineFitsWidth(
        candidate,
        style,
        maxWidth,
        direction,
        textScaler,
      );

  if (fits(text)) {
    return text;
  }

  final List<String> words =
      text.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).toList();
  if (words.isEmpty) {
    return ellipsis;
  }

  String built = words.first;
  for (int i = 1; i < words.length; i++) {
    final String trial = '$built ${words[i]}';
    if (fits('$trial$ellipsis')) {
      built = trial;
    } else {
      break;
    }
  }

  if (fits('$built$ellipsis')) {
    return '$built$ellipsis';
  }

  String prefix = built;
  while (prefix.isNotEmpty) {
    final String candidate = '$prefix$ellipsis';
    if (fits(candidate)) {
      return candidate;
    }
    prefix = Characters(prefix).skipLast(1).toString();
  }
  return ellipsis;
}
