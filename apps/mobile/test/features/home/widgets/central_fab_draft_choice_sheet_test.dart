import 'package:chisto_mobile/features/reports/presentation/widgets/draft/draft_choice_sheet.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_summary_projector.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('central FAB draft sheet continue pops with choice', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    CentralFabDraftChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showCentralFabDraftChoiceSheet(
                    context: context,
                    summary: const ReportDraftSummary(
                      hasDraft: true,
                      photoCount: 2,
                      titlePreview: 'River',
                      lastPersistedAtMs: 1,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue draft'));
    await tester.pumpAndSettle();
    expect(result, CentralFabDraftChoice.continueDraft);
  });
}
