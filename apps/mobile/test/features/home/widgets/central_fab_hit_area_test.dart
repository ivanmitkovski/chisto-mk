import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

/// Mirrors the fixed home-shell FAB overlay geometry:
/// full-screen stack + [Positioned] bottom inset + 30.
class _FabOverlayHitTestHarness extends StatelessWidget {
  const _FabOverlayHitTestHarness({
    required this.onFabPressed,
    required this.onBackgroundPressed,
  });

  final VoidCallback onFabPressed;
  final VoidCallback onBackgroundPressed;

  static const double fabSize = 64;
  static const double fabBottomOffset = 30;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBackgroundPressed,
          child: const ColoredBox(
            color: AppColors.appBackground,
            child: SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset + fabBottomOffset,
          child: Center(
            child: Semantics(
              button: true,
              label: 'Report pollution',
              child: GestureDetector(
                onTap: onFabPressed,
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.fabPrimary(),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.textOnDark,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reproduces the pre-fix layout where the FAB overflows above a 64px bar stack.
class _LegacyOverflowFabHarness extends StatelessWidget {
  const _LegacyOverflowFabHarness({
    required this.onFabPressed,
    required this.onBackgroundPressed,
  });

  final VoidCallback onFabPressed;
  final VoidCallback onBackgroundPressed;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBackgroundPressed,
          child: const ColoredBox(
            color: AppColors.appBackground,
            child: SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ColoredBox(
            color: AppColors.panelBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -30,
                        child: Center(
                          child: GestureDetector(
                            onTap: onFabPressed,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: bottomInset),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Widget child,
  double bottomInset = 34,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('fixed overlay FAB top edge is tappable without pass-through', (
    WidgetTester tester,
  ) async {
    var fabPressed = false;
    var backgroundPressed = false;

    await _pumpHarness(
      tester,
      child: _FabOverlayHitTestHarness(
        onFabPressed: () => fabPressed = true,
        onBackgroundPressed: () => backgroundPressed = true,
      ),
    );

    final Finder fab = find.byIcon(Icons.add_rounded);
    expect(fab, findsOneWidget);

    final Offset topLeft = tester.getTopLeft(fab);
    final Size size = tester.getSize(fab);
    await tester.tapAt(topLeft + Offset(size.width / 2, 4));
    await tester.pump();

    expect(fabPressed, isTrue);
    expect(backgroundPressed, isFalse);
  });

  testWidgets('fixed overlay FAB center is tappable without pass-through', (
    WidgetTester tester,
  ) async {
    var fabPressed = false;
    var backgroundPressed = false;

    await _pumpHarness(
      tester,
      child: _FabOverlayHitTestHarness(
        onFabPressed: () => fabPressed = true,
        onBackgroundPressed: () => backgroundPressed = true,
      ),
    );

    final Finder fab = find.byIcon(Icons.add_rounded);
    final Offset center = tester.getCenter(fab);
    await tester.tapAt(center);
    await tester.pump();

    expect(fabPressed, isTrue);
    expect(backgroundPressed, isFalse);
  });

  testWidgets('legacy overflow FAB top edge passes taps to background', (
    WidgetTester tester,
  ) async {
    var fabPressed = false;
    var backgroundPressed = false;

    await _pumpHarness(
      tester,
      child: _LegacyOverflowFabHarness(
        onFabPressed: () => fabPressed = true,
        onBackgroundPressed: () => backgroundPressed = true,
      ),
    );

    final Finder fab = find.byIcon(Icons.add_rounded);
    final Offset topLeft = tester.getTopLeft(fab);
    final Size size = tester.getSize(fab);
    await tester.tapAt(topLeft + Offset(size.width / 2, 4));
    await tester.pump();

    expect(fabPressed, isFalse);
    expect(backgroundPressed, isTrue);
  });
}
