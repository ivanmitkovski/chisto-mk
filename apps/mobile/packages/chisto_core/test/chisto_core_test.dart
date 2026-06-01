import 'package:chisto_core/chisto_core.dart';
import 'package:test/test.dart';

void main() {
  test('AppError network factory is retryable', () {
    final AppError error = AppError.network();
    expect(error.code, 'NETWORK_ERROR');
    expect(error.retryable, isTrue);
  });

  test('normalizeToE164 handles local trunk prefix', () {
    expect(normalizeToE164('070 123 456'), '+38970123456');
  });

  test('formatMacedonianLocalPhone matches national part formatter', () {
    expect(formatMacedonianLocalPhone('70123456'), '70 123 456');
    expect(formatPhoneNationalPart('+38970123456'), '70 123 456');
  });

  group('RelativeTimeFormatter', () {
    final _TestLabels labels = _TestLabels();

    test('notifications preset uses short date after 7 days', () {
      const RelativeTimeFormatter formatter = RelativeTimeFormatter(
        RelativeTimeFormatOptions.notifications,
      );
      final DateTime now = DateTime.utc(2026, 5, 30);
      final String s = formatter.format(labels, DateTime.utc(2026, 5, 1), now);
      expect(s, '01.05');
    });

    test('analytics preset uses weeks after 7 days', () {
      const RelativeTimeFormatter formatter = RelativeTimeFormatter(
        RelativeTimeFormatOptions.analytics,
      );
      final DateTime now = DateTime.utc(2026, 5, 30);
      expect(
        formatter.format(labels, DateTime.utc(2026, 5, 1), now),
        'weeks:3',
      );
    });
  });

  group('DistanceFormatter', () {
    test('formatSiteCardKm uses meters under 1 km', () {
      expect(
        DistanceFormatter.formatSiteCardKm(0.5, _TestDistanceLabels()),
        'm:500',
      );
    });
  });

  group('OutboxBackoffScheduler', () {
    test('chatOutboxRetryDelayAfterAttempt grows then caps', () {
      expect(
        chatOutboxRetryDelayAfterAttempt(0),
        const Duration(milliseconds: 200),
      );
      expect(chatOutboxRetryDelayAfterAttempt(20).inMilliseconds, 30000);
    });
  });
}

class _TestLabels implements RelativeTimeLabels {
  @override
  String get justNow => 'now';

  @override
  String minutes(int count) => 'm:$count';

  @override
  String hours(int count) => 'h:$count';

  @override
  String days(int count) => 'd:$count';

  @override
  String weeks(int count) => 'weeks:$count';

  @override
  String shortCalendarDate(DateTime local) =>
      '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';

  @override
  String longCalendarDate(DateTime local) => shortCalendarDate(local);
}

class _TestDistanceLabels implements SiteCardDistanceLabels {
  @override
  String meters(int meters) => 'm:$meters';

  @override
  String kilometersShort(String formattedKm) => 'k:$formattedKm';

  @override
  String kilometersWhole(String formattedKm) => 'K:$formattedKm';
}
