import 'package:flutter_test/flutter_test.dart';

/// [pumpAndSettle] with a cap so tests do not hang on repeating animations.
Future<void> pumpUntilIdle(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 100),
  Duration max = const Duration(seconds: 5),
}) {
  return tester.pumpAndSettle(step, EnginePhase.sendSemanticsUpdate, max);
}
