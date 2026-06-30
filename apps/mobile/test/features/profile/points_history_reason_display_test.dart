import 'package:chisto_infrastructure/l10n/app_localizations_en.dart';
import 'package:feature_profile/src/presentation/utils/points_history_reason_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  group('pointsHistoryReasonTitle', () {
    test('maps known reason codes to localized titles', () {
      expect(
        pointsHistoryReasonTitle(l10n, 'FIRST_REPORT'),
        l10n.profilePointsReasonFirstReport,
      );
      expect(
        pointsHistoryReasonTitle(l10n, 'EVENT_CHECK_IN'),
        l10n.profilePointsReasonEventCheckIn,
      );
    });

    test('falls back to other for unknown codes', () {
      expect(
        pointsHistoryReasonTitle(l10n, 'UNKNOWN_CODE'),
        l10n.profilePointsReasonOther,
      );
    });
  });

  group('pointsHistoryReasonIcon', () {
    test('returns distinct icons for report and event codes', () {
      expect(
        pointsHistoryReasonIcon('REPORT_APPROVED'),
        Icons.verified_outlined,
      );
      expect(
        pointsHistoryReasonIcon('EVENT_JOIN_NO_SHOW'),
        Icons.event_busy_outlined,
      );
    });

    test('falls back to stars icon for unknown codes', () {
      expect(pointsHistoryReasonIcon('UNKNOWN'), Icons.stars_rounded);
    });
  });

  group('pointsHistoryDeltaLabel', () {
    test('formats positive deltas with plus sign', () {
      expect(
        pointsHistoryDeltaLabel(l10n, 5),
        l10n.profilePointsDeltaPositive(5),
      );
    });

    test('formats negative deltas without plus sign', () {
      expect(
        pointsHistoryDeltaLabel(l10n, -3),
        l10n.profilePointsDeltaNegative(-3),
      );
    });

    test('treats zero as positive', () {
      expect(
        pointsHistoryDeltaLabel(l10n, 0),
        l10n.profilePointsDeltaPositive(0),
      );
    });
  });
}
