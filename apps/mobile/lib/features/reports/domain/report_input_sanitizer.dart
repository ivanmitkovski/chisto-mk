import 'package:chisto_mobile/features/reports/domain/report_field_limits.dart';

/// Client-side normalization for report text fields (defense in depth; server remains authoritative).
class ReportInputSanitizer {
  const ReportInputSanitizer._();

  /// Strips control characters except tab/newline/carriage return in description.
  static String sanitizeTitle(String raw) {
    return _stripControls(raw, allowNewlines: false).trim();
  }

  /// Allows single newlines for paragraph breaks.
  static String sanitizeDescription(String raw) {
    return _stripControls(raw, allowNewlines: true).trim();
  }

  static String _stripControls(String raw, {required bool allowNewlines}) {
    final StringBuffer out = StringBuffer();
    for (final int rune in raw.runes) {
      if (rune == 0x9 || rune == 0xA || rune == 0xD) {
        if (allowNewlines && (rune == 0xA || rune == 0xD)) {
          out.writeCharCode(rune);
        } else if (rune == 0x9) {
          out.writeCharCode(0x20);
        }
        continue;
      }
      if (rune < 0x20) {
        continue;
      }
      out.writeCharCode(rune);
    }
    return out.toString();
  }

  static String clampTitle(String s) {
    final String t = sanitizeTitle(s);
    if (t.length <= ReportFieldLimits.maxTitleLength) return t;
    return t.substring(0, ReportFieldLimits.maxTitleLength);
  }

  static String clampDescription(String s) {
    final String t = sanitizeDescription(s);
    if (t.length <= ReportFieldLimits.maxDescriptionLength) return t;
    return t.substring(0, ReportFieldLimits.maxDescriptionLength);
  }
}
