import 'package:chisto_infrastructure/core/network/realtime_disruption_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealtimeDisruptionSignal', () {
    test('hides banner during grace and shows after sustained outage', () async {
      final RealtimeDisruptionSignal signal = RealtimeDisruptionSignal(
        channel: 'test',
        gracePeriod: const Duration(milliseconds: 50),
      );
      addTearDown(signal.dispose);

      expect(signal.visible.value, isFalse);

      signal.setLive(isLive: false);
      expect(signal.visible.value, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(signal.visible.value, isTrue);
    });

    test('recovers within grace without showing banner', () async {
      final RealtimeDisruptionSignal signal = RealtimeDisruptionSignal(
        channel: 'test',
        gracePeriod: const Duration(milliseconds: 80),
      );
      addTearDown(signal.dispose);

      signal.setLive(isLive: false);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      signal.setLive(isLive: true);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(signal.visible.value, isFalse);
    });

    test('hides immediately on reconnect after banner was shown', () async {
      final RealtimeDisruptionSignal signal = RealtimeDisruptionSignal(
        channel: 'test',
        gracePeriod: const Duration(milliseconds: 20),
      );
      addTearDown(signal.dispose);

      signal.setLive(isLive: false);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(signal.visible.value, isTrue);

      signal.setLive(isLive: true);
      expect(signal.visible.value, isFalse);
    });
  });
}
