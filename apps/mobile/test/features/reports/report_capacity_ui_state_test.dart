import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  group('mapReportCapacityToUiState', () {
    test('maps healthy state', () {
      final ui = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 8,
          emergencyAvailable: true,
          emergencyWindowDays: 7,
          retryAfterSeconds: null,
          nextEmergencyReportAvailableAt: null,
          unlockHint: 'Unlock hint',
        ),
        l10n: l10n,
      );

      expect(ui.kind, ReportCapacityUiKind.healthy);
      expect(ui.pillLabel, l10n.reportCapacityPillHealthy(8));
      expect(ui.reviewMessage, l10n.reportCapacityReviewHealthy);
    });

    test('maps low state', () {
      final ui = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 1,
          emergencyAvailable: true,
          emergencyWindowDays: 7,
          retryAfterSeconds: null,
          nextEmergencyReportAvailableAt: null,
          unlockHint: 'Unlock hint',
        ),
        l10n: l10n,
      );

      expect(ui.kind, ReportCapacityUiKind.low);
      expect(ui.pillLabel, l10n.reportCapacityPillLow(1));
      expect(ui.bannerMessage, contains(l10n.reportCapacityUnlockHint));
    });

    test('maps emergency and cooldown states', () {
      final emergency = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 0,
          emergencyAvailable: true,
          emergencyWindowDays: 7,
          retryAfterSeconds: null,
          nextEmergencyReportAvailableAt: null,
          unlockHint: 'Unlock hint',
        ),
        l10n: l10n,
      );
      final cooldown = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 0,
          emergencyAvailable: false,
          emergencyWindowDays: 7,
          retryAfterSeconds: 7260,
          nextEmergencyReportAvailableAt: null,
          unlockHint: 'Unlock hint',
        ),
        l10n: l10n,
      );

      expect(emergency.kind, ReportCapacityUiKind.emergency);
      expect(emergency.reviewMessage, contains('emergency'));
      expect(cooldown.kind, ReportCapacityUiKind.cooldown);
      expect(cooldown.bannerMessage, contains('~'));
      expect(cooldown.bannerMessage, contains('2 hours'));
      expect(cooldown.bannerMessage, contains('1 minute'));
    });
  });
}
