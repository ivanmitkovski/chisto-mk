import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appSheetSizeAfterDrag', () {
    test('downward delta shrinks the sheet', () {
      expect(
        appSheetSizeAfterDrag(
          size: 0.74,
          deltaSize: 0.1,
          minSize: 0.56,
          maxSize: 0.95,
        ),
        0.64,
      );
    });
  });

  group('resolveAppSheetDragEnd', () {
    AppSheetDragEndResult resolve({
      required double size,
      double? velocity,
    }) {
      return resolveAppSheetDragEnd(
        size: size,
        velocity: velocity,
        minSize: 0.56,
        maxSize: 0.95,
        snapSizes: const <double>[0.74, 0.95],
      );
    }

    test('downward fling at min dismisses', () {
      final AppSheetDragEndResult result = resolve(
        size: 0.56,
        velocity: kAppSheetFlingVelocity + 1,
      );
      expect(result.action, AppSheetDragEndAction.dismiss);
    });

    test('slow drag snaps to nearest candidate', () {
      final AppSheetDragEndResult result = resolve(size: 0.8, velocity: 50);
      expect(result.action, AppSheetDragEndAction.animateTo);
      expect(result.targetSize, 0.74);
    });
  });
}
