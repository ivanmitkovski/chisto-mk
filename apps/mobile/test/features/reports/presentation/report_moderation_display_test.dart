import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_moderation_display.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  group('declineReasonFromApi', () {
    test('returns reason only for deleted status', () {
      expect(
        declineReasonFromApi(
          ApiReportStatus.deleted,
          'Insufficient evidence. Notes: More detail',
        ),
        'Insufficient evidence. Notes: More detail',
      );
      expect(declineReasonFromApi(ApiReportStatus.approved, 'hidden'), isNull);
      expect(declineReasonFromApi(ApiReportStatus.deleted, '  '), isNull);
    });
  });

  testWidgets(
    'ReportSheetViewModelMapper sets declineReason on declined list item',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              final ReportSheetViewModel
              vm = ReportSheetViewModelMapper.fromListItem(
                ReportListItem(
                  id: 'r1',
                  reportNumber: 'CH-1',
                  title: 'Dump site',
                  location: 'Skopje',
                  submittedAt: DateTime(2026, 6, 1),
                  status: ApiReportStatus.deleted,
                  isPotentialDuplicate: false,
                  coReporterCount: 0,
                  moderationReason:
                      'Insufficient evidence. Notes: The evidence is not enough',
                ),
                AppLocalizations.of(context)!,
              );
              return Text(vm.declineReason ?? '');
            },
          ),
        ),
      );

      expect(
        find.text('Insufficient evidence. Notes: The evidence is not enough'),
        findsOneWidget,
      );
    },
  );
}
