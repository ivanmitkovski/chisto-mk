import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';

/// Regression coverage for the onboarding CTA being hidden behind the Android
/// navigation bar / iOS home indicator.
///
/// The bottom panel is edge-to-edge (it draws behind the system bars), so the
/// CTA's own padding must absorb the full bottom system inset plus a fixed
/// visual gap. Previously the inset was clamped to <= 22px, leaving the button
/// covered by the ~48dp Android 3-button navigation bar.
void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  // Visual gap the CTA keeps above the system inset (AppSpacing.radius14 in
  // OnboardingScreen). Used to assert "above the bar" without being arbitrary.
  const double kCtaGap = 14;

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required Size size,
    required double bottomInset,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      pumpAuthScreen(
        // Inner MediaQuery overrides the harness default so we can simulate a
        // real device's bottom system inset (gesture pill / nav bar).
        home: MediaQuery(
          data: kAuthTestMediaQuery.copyWith(
            size: size,
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const OnboardingScreen(),
        ),
        overrides: AuthTestOverrides().build(),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Small/budget, Pixel-class, and the standard auth surface.
  const List<Size> deviceSizes = <Size>[
    Size(360, 690),
    Size(411, 891),
    Size(480, 900),
  ];

  // none, gesture pill, iOS home indicator, Android 3-button nav bar.
  const List<double> bottomInsets = <double>[0, 24, 34, 48];

  for (final Size size in deviceSizes) {
    for (final double inset in bottomInsets) {
      testWidgets('CTA stays above a ${inset}px bottom inset on '
          '${size.width.toInt()}x${size.height.toInt()}', (
        WidgetTester tester,
      ) async {
        await pumpOnboarding(tester, size: size, bottomInset: inset);

        final Rect cta = tester.getRect(find.byType(AppButton));
        final double systemBarTop = size.height - inset;

        // The button never extends into the system navigation area.
        expect(
          cta.bottom,
          lessThanOrEqualTo(systemBarTop),
          reason:
              'CTA bottom (${cta.bottom}) overlaps the system bar starting '
              'at $systemBarTop (inset $inset).',
        );
        // And it keeps the designed breathing room above it.
        expect(
          systemBarTop - cta.bottom,
          closeTo(kCtaGap, 1.0),
          reason: 'Expected ~$kCtaGap px gap above the $inset px inset.',
        );
      });
    }
  }

  testWidgets('CTA clears the nav bar and copy does not overflow on a tiny, '
      'large-text device', (WidgetTester tester) async {
    // Worst case: short screen + 3-button nav bar + accessibility text scale.
    // testWidgets fails on any RenderFlex overflow, so a clean pump asserts
    // the slide copy scales down instead of overflowing.
    await pumpOnboarding(
      tester,
      size: const Size(320, 600),
      bottomInset: 48,
      textScale: 1.5,
    );

    final Rect cta = tester.getRect(find.byType(AppButton));
    expect(cta.bottom, lessThanOrEqualTo(600.0 - 48.0));
    expect(find.text('Continue'), findsOneWidget);
  });
}
