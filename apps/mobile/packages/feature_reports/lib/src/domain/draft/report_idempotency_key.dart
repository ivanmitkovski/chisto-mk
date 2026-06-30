import 'dart:convert';
import 'dart:math';

/// Generates idempotency keys compatible with API
/// `^[A-Za-z0-9_-]{16,128}$` (see `report-submit.service.ts`).
class ReportIdempotencyKey {
  const ReportIdempotencyKey._();

  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

  /// Cryptographically suitable key (22 chars from 16 random bytes, base64url).
  static String generate() {
    final Random r = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => r.nextInt(256));
    // API allows only `[A-Za-z0-9_-]` — strip base64 padding `=`.
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static bool isValidShape(String key) => _pattern.hasMatch(key.trim());
}
