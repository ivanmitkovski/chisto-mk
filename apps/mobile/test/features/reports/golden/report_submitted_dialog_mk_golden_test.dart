import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_submitted_dialog.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ReportSubmittedDialog golden mk', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('mk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(420, 900),
            devicePixelRatio: 1.0,
            textScaler: TextScaler.linear(1.0),
            disableAnimations: true,
          ),
          child: Center(
            child: ReportSubmittedDialog(
              categoryLabel: 'Нелегална депонија',
              reportNumber: 'R-25-XXXX',
              reportId: 'rep-golden-1',
              address: 'Скопје',
              pointsAwarded: 12,
              isNewSite: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await expectLater(
      find.byType(ReportSubmittedDialog),
      matchesGoldenFile('__goldens__/report_submitted_dialog_mk.png'),
    );
  });
}
