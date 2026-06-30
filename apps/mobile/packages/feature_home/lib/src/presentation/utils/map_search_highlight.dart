import 'package:feature_home/src/presentation/utils/map_search_text.dart';
import 'package:flutter/material.dart';

/// Builds spans that bold each search term in [text] (case/script insensitive).
List<InlineSpan> mapSearchHighlightSpans({
  required String text,
  required String rawQuery,
  required TextStyle baseStyle,
  required TextStyle emphasisStyle,
}) {
  final List<String> terms = mapSearchTerms(rawQuery);
  if (terms.isEmpty || text.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }

  final List<_HighlightRange> ranges = _highlightRangesForTerms(text, terms);
  if (ranges.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }

  final List<InlineSpan> out = <InlineSpan>[];
  int cursor = 0;
  for (final _HighlightRange range in ranges) {
    if (range.start > cursor) {
      out.add(
        TextSpan(text: text.substring(cursor, range.start), style: baseStyle),
      );
    }
    out.add(
      TextSpan(
        text: text.substring(range.start, range.end),
        style: emphasisStyle,
      ),
    );
    cursor = range.end;
  }
  if (cursor < text.length) {
    out.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return out;
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end);

  final int start;
  final int end;
}

List<_HighlightRange> _highlightRangesForTerms(
  String text,
  List<String> terms,
) {
  final List<_HighlightRange> ranges = <_HighlightRange>[];
  final String foldedText = foldMapSearchText(text);

  for (final String term in terms) {
    final String foldedTerm = foldMapSearchText(term);
    if (foldedTerm.isEmpty) {
      continue;
    }
    int searchFrom = 0;
    while (searchFrom < foldedText.length) {
      final int idx = foldedText.indexOf(foldedTerm, searchFrom);
      if (idx < 0) {
        break;
      }
      ranges.add(_HighlightRange(idx, idx + foldedTerm.length));
      searchFrom = idx + foldedTerm.length;
    }
  }

  if (ranges.isEmpty) {
    return ranges;
  }

  ranges.sort(
    (_HighlightRange a, _HighlightRange b) => a.start.compareTo(b.start),
  );
  final List<_HighlightRange> merged = <_HighlightRange>[ranges.first];
  for (int i = 1; i < ranges.length; i++) {
    final _HighlightRange prev = merged.last;
    final _HighlightRange cur = ranges[i];
    if (cur.start <= prev.end) {
      merged[merged.length - 1] = _HighlightRange(
        prev.start,
        cur.end > prev.end ? cur.end : prev.end,
      );
    } else {
      merged.add(cur);
    }
  }
  return merged;
}
