import 'package:flutter/material.dart';

/// Builds spans that bold the first case-insensitive match of [query] in [text].
List<InlineSpan> mapSearchHighlightSpans({
  required String text,
  required String rawQuery,
  required TextStyle baseStyle,
  required TextStyle emphasisStyle,
}) {
  final String q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }
  final String lower = text.toLowerCase();
  final List<InlineSpan> out = <InlineSpan>[];
  int start = 0;
  while (true) {
    final int idx = lower.indexOf(q, start);
    if (idx < 0) {
      if (start < text.length) {
        out.add(TextSpan(text: text.substring(start), style: baseStyle));
      }
      break;
    }
    if (idx > start) {
      out.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
    }
    out.add(
      TextSpan(
        text: text.substring(idx, idx + q.length),
        style: emphasisStyle,
      ),
    );
    start = idx + q.length;
  }
  return out;
}
