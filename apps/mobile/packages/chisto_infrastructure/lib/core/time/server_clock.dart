import 'package:flutter/foundation.dart';

/// Tracks the offset between the device clock and the server clock.
///
/// We sample the offset from the `Date` response header of every successful
/// API call. The offset (`serverNowMs - deviceNowMs`) is then applied to
/// [DateTime.now] when callers ask [now] / [millisecondsSinceEpoch], giving
/// the rest of the app a single source of "server time" without each call
/// site having to plumb a [Clock].
///
/// We use a smoothed offset (1/4-weight EMA) so a single slow request can't
/// rotate the clock by hundreds of milliseconds. The smoothed value sits
/// inside a [ValueNotifier] so listeners (e.g. event CTAs) can re-render
/// when the offset stabilizes.
class ServerClock {
  ServerClock._();

  static final ServerClock instance = ServerClock._();

  /// Smoothed `server - device` offset in milliseconds. Defaults to `0` so
  /// the app behaves exactly like [DateTime.now] until the first sample.
  final ValueNotifier<int> offsetMs = ValueNotifier<int>(0);

  /// Last raw sample (debugging only).
  int? _lastSampleMs;
  int? get lastRawSampleMs => _lastSampleMs;

  /// Feeds a `Date` header into the smoother. Silently ignores unparseable
  /// values so callers can pipe headers in without try/catch.
  void recordDateHeader(String? dateHeader) {
    if (dateHeader == null || dateHeader.isEmpty) return;
    DateTime? parsed;
    try {
      parsed = HttpDate.parse(dateHeader);
    } on Object {
      parsed = null;
    }
    parsed ??= DateTime.tryParse(dateHeader);
    if (parsed == null) return;
    final int serverMs = parsed.toUtc().millisecondsSinceEpoch;
    final int deviceMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final int sample = serverMs - deviceMs;
    _lastSampleMs = sample;
    // Weighted EMA: 25% new sample, 75% prior offset. Clamps the influence
    // of any single laggy request while still converging quickly.
    final int prev = offsetMs.value;
    final int next = ((prev * 3) + sample) ~/ 4;
    if (next != prev) {
      offsetMs.value = next;
    }
  }

  /// Current server-aligned [DateTime] (UTC).
  DateTime nowUtc() {
    final DateTime device = DateTime.now().toUtc();
    return device.add(Duration(milliseconds: offsetMs.value));
  }

  /// Current server-aligned [DateTime] (local zone).
  DateTime now() => nowUtc().toLocal();

  /// Resets the smoother. Used on logout / account switch so we don't keep
  /// a previous user's smoothed offset.
  void reset() {
    offsetMs.value = 0;
    _lastSampleMs = null;
  }
}

/// Minimal RFC1123 parser. The `http` package exposes one via
/// `HttpDate.parse`, but importing `dart:io` from a code path that has to
/// stay web-compatible breaks. Re-implement just enough for `Date:` headers.
class HttpDate {
  static DateTime parse(String input) {
    // Try ISO-8601 first (some proxies do this).
    final DateTime? iso = DateTime.tryParse(input);
    if (iso != null) return iso.toUtc();
    final RegExp rfc1123 = RegExp(
      r'^[A-Za-z]{3},\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s+GMT$',
    );
    final RegExpMatch? m = rfc1123.firstMatch(input.trim());
    if (m == null) {
      throw FormatException('Unrecognized HTTP-date: $input');
    }
    const Map<String, int> months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final int day = int.parse(m.group(1)!);
    final int month = months[m.group(2)!] ?? 1;
    final int year = int.parse(m.group(3)!);
    final int hour = int.parse(m.group(4)!);
    final int minute = int.parse(m.group(5)!);
    final int second = int.parse(m.group(6)!);
    return DateTime.utc(year, month, day, hour, minute, second);
  }
}
