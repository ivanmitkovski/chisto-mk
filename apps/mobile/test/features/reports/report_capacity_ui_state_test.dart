import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapReportCapacityToUiState', () {
    test('maps healthy state', () {
      final ui = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 8,
          emergencyAvailable: true,
          emergencyWindowDays: 7,
          retryAfterSeconds: null,
          unlockHint: 'Unlock hint',
        ),
      );

      expect(ui.kind, ReportCapacityUiKind.healthy);
      expect(ui.pillLabel, '8 reports available');
      expect(ui.reviewMessage, contains('use 1 report credit'));
    });

    test('maps low state', () {
      final ui = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 1,
          emergencyAvailable: true,
          emergencyWindowDays: 7,
          retryAfterSeconds: null,
          unlockHint: 'Unlock hint',
        ),
      );

      expect(ui.kind, ReportCapacityUiKind.low);
      expect(ui.pillLabel, '1 report left');
      expect(ui.bannerMessage, contains('Unlock hint'));
    });

    test('maps emergency and cooldown states', () {
      final emergency = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 0,
          emergencyAvailable: true,
          emergencyWindowDays: 7,
          retryAfterSeconds: null,
          unlockHint: 'Unlock hint',
        ),
      );
      final cooldown = mapReportCapacityToUiState(
        const ReportCapacity(
          creditsAvailable: 0,
          emergencyAvailable: false,
          emergencyWindowDays: 7,
          retryAfterSeconds: 3700,
          unlockHint: 'Unlock hint',
        ),
      );

      expect(emergency.kind, ReportCapacityUiKind.emergency);
      expect(emergency.reviewMessage, contains('emergency report allowance'));
      expect(cooldown.kind, ReportCapacityUiKind.cooldown);
      expect(cooldown.bannerMessage, contains('about 2h'));
    });
  });
}
