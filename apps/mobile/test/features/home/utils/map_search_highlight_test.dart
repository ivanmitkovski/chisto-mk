import 'package:feature_home/src/presentation/utils/map_search_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapSearchHighlightSpans bolds each term', () {
    const TextStyle base = TextStyle();
    const TextStyle emphasis = TextStyle(fontWeight: FontWeight.w700);

    final List<InlineSpan> spans = mapSearchHighlightSpans(
      text: 'River plastic near Bitola',
      rawQuery: 'river bitola',
      baseStyle: base,
      emphasisStyle: emphasis,
    );

    final String rendered = spans
        .whereType<TextSpan>()
        .map((TextSpan span) => span.text ?? '')
        .join();
    expect(rendered, 'River plastic near Bitola');

    final int emphasizedCount = spans
        .whereType<TextSpan>()
        .where((TextSpan span) => span.style?.fontWeight == FontWeight.w700)
        .length;
    expect(emphasizedCount, greaterThanOrEqualTo(2));
  });
}
