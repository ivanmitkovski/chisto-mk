/// Normalizes user-entered comment text before send (trim, strip tags, collapse space).
class CommentInputValidator {
  CommentInputValidator._();

  static String normalizeBody(String raw) {
    String s = raw.trim();
    if (s.isEmpty) {
      return s;
    }
    s = s.replaceAll(RegExp('<[^>]*>'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static bool withinMaxLength(String s, {int maxLength = 2000}) {
    return s.length <= maxLength;
  }
}
