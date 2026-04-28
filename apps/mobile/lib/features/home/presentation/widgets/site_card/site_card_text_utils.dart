import 'package:flutter/painting.dart';

/// Word-boundary truncation for feed card title/description (single source of truth).
String truncateSiteCardTextAtWordBoundary(
  String text, {
  required TextStyle style,
  required double maxWidth,
  required int maxLines,
}) {
  if (text.isEmpty) {
    return text;
  }
  const String ellipsis = '…';
  final TextSpan ellipsisSpan = TextSpan(text: ellipsis, style: style);
  final TextPainter ellipsisPainter = TextPainter(
    text: ellipsisSpan,
    textDirection: TextDirection.ltr,
  )..layout();
  final double ellipsisWidth = ellipsisPainter.width;
  final double availableWidth = (maxWidth - ellipsisWidth).clamp(
    1.0,
    double.infinity,
  );
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: availableWidth);
  if (!painter.didExceedMaxLines) {
    return text;
  }
  final Offset endOffset = Offset(availableWidth, painter.size.height - 1);
  final TextPosition position = painter.getPositionForOffset(endOffset);
  final int offset = position.offset.clamp(0, text.length);
  final int lastSpace = offset > 0 ? text.lastIndexOf(' ', offset - 1) : -1;
  if (lastSpace > 0) {
    return '${text.substring(0, lastSpace).trimRight()}$ellipsis';
  }
  return '${text.substring(0, offset).trimRight()}$ellipsis';
}
