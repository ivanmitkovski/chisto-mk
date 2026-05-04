import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_config.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_help.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Report stage help sheet', () {
    testWidgets('shows localized section titles in fit-to-content sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              final AppLocalizations l10n = AppLocalizations.of(context)!;
              final ReportStageConfig cfg = ReportStage.evidence.config(l10n);
              return Scaffold(
                body: ReportSheetScaffold(
                  fitToContent: true,
                  title: cfg.infoTitle,
                  subtitle: cfg.subtitle,
                  child: StageHelpFormattedContent(
                    sections: cfg.helpSections,
                    contextSectionTitle: l10n.reportHelpContextTitle,
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('What to capture'), findsOneWidget);
      expect(find.text('Why it helps'), findsOneWidget);
    });
  });
}
