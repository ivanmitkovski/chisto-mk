import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/events/data/event_offline_work_coordinator.dart';

void main() {
  group('EventOfflineWorkSnapshot', () {
    test('empty factory has zero work and idle phase', () {
      final EventOfflineWorkSnapshot s = EventOfflineWorkSnapshot.empty();
      expect(s.checkInPending, 0);
      expect(s.fieldPending, 0);
      expect(s.chatPending, 0);
      expect(s.chatFailed, 0);
      expect(s.totalWorkItems, 0);
      expect(s.phase, OfflineWorkSyncPhase.idle);
      expect(s.lastDiagnosticCode, isNull);
    });

    test('totalWorkItems sums pending and failed chat', () {
      const EventOfflineWorkSnapshot s = EventOfflineWorkSnapshot(
        checkInPending: 2,
        fieldPending: 1,
        chatPending: 3,
        chatFailed: 1,
        phase: OfflineWorkSyncPhase.needsAttention,
        lastDiagnosticCode: 'x',
      );
      expect(s.totalWorkItems, 7);
    });
  });
}
