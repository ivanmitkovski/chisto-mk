import 'package:chisto_mobile/core/time/server_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerClock', () {
    setUp(() {
      ServerClock.instance.reset();
    });

    test('ignores null / empty header', () {
      ServerClock.instance.recordDateHeader(null);
      ServerClock.instance.recordDateHeader('');
      expect(ServerClock.instance.offsetMs.value, 0);
    });

    test('rejects unparseable header without throwing', () {
      ServerClock.instance.recordDateHeader('not-a-date');
      expect(ServerClock.instance.offsetMs.value, 0);
    });

    test('samples an RFC1123 header', () {
      // 30 seconds ahead of device "now". Device clock varies in CI so we just
      // assert the offset moved by roughly the expected amount, not exact.
      final DateTime serverNow = DateTime.now().toUtc().add(const Duration(seconds: 30));
      final String header = _formatRfc1123(serverNow);
      ServerClock.instance.recordDateHeader(header);
      // EMA on first sample: (0*3 + sample)/4 — quarter of the real offset.
      expect(ServerClock.instance.offsetMs.value, greaterThan(5000));
      expect(ServerClock.instance.offsetMs.value, lessThan(15000));
    });

    test('reset() clears smoothed state', () {
      final DateTime serverNow = DateTime.now().toUtc().add(const Duration(minutes: 1));
      ServerClock.instance.recordDateHeader(_formatRfc1123(serverNow));
      expect(ServerClock.instance.offsetMs.value, isNonZero);
      ServerClock.instance.reset();
      expect(ServerClock.instance.offsetMs.value, 0);
      expect(ServerClock.instance.lastRawSampleMs, isNull);
    });
  });
}

String _formatRfc1123(DateTime utc) {
  const List<String> dayNames = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const List<String> monthNames = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dayNames[utc.weekday - 1]}, ${two(utc.day)} ${monthNames[utc.month - 1]} '
      '${utc.year} ${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} GMT';
}
