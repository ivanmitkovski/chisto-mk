import 'package:chisto_infrastructure/core/concurrency/single_flight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SingleFlight', () {
    test('coalesces concurrent invocations', () async {
      final SingleFlight<int> flight = SingleFlight<int>();
      int calls = 0;
      Future<int> task() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 42;
      }

      final Future<int> a = flight.run(task);
      final Future<int> b = flight.run(task);
      final Future<int> c = flight.run(task);

      expect(flight.isRunning, isTrue);
      expect(await Future.wait(<Future<int>>[a, b, c]), <int>[42, 42, 42]);
      expect(calls, 1);
      expect(flight.isRunning, isFalse);
    });

    test('runs new task after previous completes', () async {
      final SingleFlight<int> flight = SingleFlight<int>();
      int callCount = 0;
      Future<int> task() async {
        callCount++;
        return callCount;
      }

      expect(await flight.run(task), 1);
      expect(await flight.run(task), 2);
    });

    test('propagates the same error to all callers', () async {
      final SingleFlight<void> flight = SingleFlight<void>();
      Future<void> task() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw StateError('boom');
      }

      final Future<void> a = flight.run(task);
      final Future<void> b = flight.run(task);

      Object? errA;
      Object? errB;
      try {
        await a;
      } on Object catch (e) {
        errA = e;
      }
      try {
        await b;
      } on Object catch (e) {
        errB = e;
      }

      expect(errA, isA<StateError>());
      expect(errB, isA<StateError>());
      // Same Future ⇒ same error instance.
      expect(identical(errA, errB), isTrue);
    });
  });
}
