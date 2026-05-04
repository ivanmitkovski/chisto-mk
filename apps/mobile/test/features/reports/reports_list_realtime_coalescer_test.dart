import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/reports_list_realtime_coalescer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schedules a single refresh after rapid events', () async {
    int calls = 0;
    final ReportsListRealtimeCoalescer coalescer = ReportsListRealtimeCoalescer(
      debounce: const Duration(milliseconds: 12),
      onRefresh: () {
        calls++;
      },
    );
    coalescer.schedule();
    coalescer.schedule();
    coalescer.schedule();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(calls, 1);
    coalescer.dispose();
  });

  test('dispose cancels pending refresh', () async {
    int calls = 0;
    final ReportsListRealtimeCoalescer coalescer = ReportsListRealtimeCoalescer(
      debounce: const Duration(milliseconds: 50),
      onRefresh: () {
        calls++;
      },
    );
    coalescer.schedule();
    coalescer.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(calls, 0);
  });
}
