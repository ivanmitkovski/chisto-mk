import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/coach_tour_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CoachTourScrimPainter golden with cutout (reduce motion)', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const Rect hole = Rect.fromLTWH(120, 380, 56, 56);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 520),
            devicePixelRatio: 1.0,
            textScaler: TextScaler.linear(1.0),
            disableAnimations: true,
          ),
          child: ColoredBox(
            color: const Color(0xFFE8EAED),
            child: CustomPaint(
              painter: CoachTourScrimPainter(
                holeRectLocal: hole,
                scrimColor: AppColors.textPrimary.withValues(alpha: 0.42),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CustomPaint),
      matchesGoldenFile('__goldens__/coach_tour_scrim_cutout.png'),
    );
  });
}
