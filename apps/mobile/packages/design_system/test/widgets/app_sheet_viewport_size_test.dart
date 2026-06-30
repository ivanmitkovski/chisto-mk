import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AppSheetSizeConfig commentsBase = AppSheetSizeConfig(
    minSize: 0.56,
    maxSize: 0.95,
    snapSizes: <double>[0.74, 0.95],
    initialSize: 0.74,
  );

  test('maps legacy detents into notch-safe slot fractions', () {
    const MediaQueryData mq = MediaQueryData(
      size: Size(390, 844),
      viewPadding: EdgeInsets.only(top: 59),
    );

    final AppSheetSizeConfig config = appSheetSizeConfigForViewport(
      commentsBase,
      mq,
    );

    expect(config.maxSize, 1.0);
    expect(config.snapSizes.last, 1.0);
    expect(config.snapSizes.first, closeTo((0.74 * 844) / (844 - 59), 0.001));
    expect(
      config.resolvedInitialSize,
      closeTo((0.74 * 844) / (844 - 59), 0.001),
    );
  });

  test('keyboard insets do not change detent fractions', () {
    const MediaQueryData withoutKeyboard = MediaQueryData(
      size: Size(390, 844),
      viewPadding: EdgeInsets.only(top: 59),
    );
    const MediaQueryData withKeyboard = MediaQueryData(
      size: Size(390, 844),
      viewPadding: EdgeInsets.only(top: 59),
      viewInsets: EdgeInsets.only(bottom: 336),
    );

    final AppSheetSizeConfig closed = appSheetSizeConfigForViewport(
      commentsBase,
      withoutKeyboard,
    );
    final AppSheetSizeConfig open = appSheetSizeConfigForViewport(
      commentsBase,
      withKeyboard,
    );

    expect(open.minSize, closed.minSize);
    expect(open.maxSize, closed.maxSize);
    expect(open.snapSizes, closed.snapSizes);
    expect(open.resolvedInitialSize, closed.resolvedInitialSize);
  });

  test('keyboard open sheet top stays below notch on screen', () {
    const double screenHeight = 844;
    const double topInset = 59;
    const double keyboardInset = 336;
    const MediaQueryData mq = MediaQueryData(
      size: Size(390, screenHeight),
      viewPadding: EdgeInsets.only(top: topInset),
    );

    final AppSheetSizeConfig config = appSheetSizeConfigForViewport(
      commentsBase,
      mq,
    );
    final double slotHeight = appSheetViewportSlotHeight(
      screenHeight: screenHeight,
      topInset: topInset,
      keyboardInset: keyboardInset,
    );
    final double sheetHeight = config.maxSize * slotHeight;
    const double sheetTop = topInset;
    final double sheetBottom = sheetTop + sheetHeight;

    expect(sheetTop, greaterThanOrEqualTo(topInset));
    expect(sheetBottom, closeTo(screenHeight - keyboardInset, 1));
  });

  test('screen fraction to slot conversion', () {
    expect(
      appSheetScreenFractionToSlot(
        screenFraction: 0.95,
        screenHeight: 844,
        slotHeight: 844 - 59,
      ),
      closeTo(1.0, 0.001),
    );
    expect(
      appSheetScreenFractionToSlot(
        screenFraction: 0.74,
        screenHeight: 844,
        slotHeight: 844 - 59,
      ),
      closeTo((0.74 * 844) / (844 - 59), 0.001),
    );
  });
}
