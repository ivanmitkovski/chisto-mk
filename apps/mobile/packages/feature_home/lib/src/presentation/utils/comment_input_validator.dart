/// Normalizes user-entered comment text before send (trim, strip tags, collapse space).
class CommentInputValidator {
  CommentInputValidator._();

  /// Matches API `@MaxLength(500)` on site comment DTOs.
  static const int maxBodyLength = 500;

  static String normalizeBody(String raw) {
    String s = raw.trim();
    if (s.isEmpty) {
      return s;
    }
    s = s.replaceAll(RegExp('<[^>]*>'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static int normalizedLength(String raw) => normalizeBody(raw).length;

  static bool withinMaxLength(String s, {int? maxLength}) {
    return s.length <= (maxLength ?? maxBodyLength);
  }
}
