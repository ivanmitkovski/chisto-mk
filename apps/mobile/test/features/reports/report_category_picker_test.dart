import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/l10n/report_category_l10n.dart';
import 'package:feature_reports/src/presentation/widgets/report_category_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows grouped category options with sheet subtitle only', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showReportCategoryPicker(
                      context,
                      selected: null,
                      onSelected: (_) {},
                    );
                  },
                  child: const Text('Open category picker'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open category picker'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportCategoryPickerSubtitle), findsOneWidget);
    expect(find.text(l10n.reportCategoryPickerBannerBody), findsNothing);
    expect(find.byType(AppSelectionInstruction), findsNothing);
    expect(find.byType(AppGroupedActionList), findsOneWidget);

    final Finder groupedTiles = find.descendant(
      of: find.byType(AppGroupedActionList),
      matching: find.byType(AppActionTile),
    );
    expect(groupedTiles, findsNWidgets(ReportCategory.values.length));

    final AppActionTile firstTile = tester.widget<AppActionTile>(
      groupedTiles.first,
    );
    expect(firstTile.title, ReportCategory.values.first.localizedTitle(l10n));
    expect(firstTile.variant, AppActionTileVariant.grouped);
  });

  testWidgets('category picker sheet hugs its option list', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late AppLocalizations l10n;

    await tester.pumpWidget(
      wrapForWidgetTest(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, screenHeight),
            padding: EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: EdgeInsets.only(top: 59, bottom: 34),
          ),
          child: Builder(
            builder: (BuildContext context) {
              l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showReportCategoryPicker(
                        context,
                        selected: null,
                        onSelected: (_) {},
                      );
                    },
                    child: const Text('Open category picker'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open category picker'));
    await tester.pumpAndSettle();

    final RenderBox sheetBox = tester.renderObject<RenderBox>(
      find.byType(AppSheetScaffold),
    );
    final String lastCategoryTitle = ReportCategory.values.last.localizedTitle(
      l10n,
    );

    expect(sheetBox.size.height, lessThan(screenHeight * 0.75));
    expect(sheetBox.localToGlobal(Offset.zero).dy, greaterThan(59));

    final RenderBox lastOptionBox = tester.renderObject<RenderBox>(
      find.text(lastCategoryTitle),
    );
    final double sheetBottom =
        sheetBox.localToGlobal(Offset.zero).dy + sheetBox.size.height;
    final double lastOptionBottom =
        lastOptionBox.localToGlobal(Offset.zero).dy + lastOptionBox.size.height;
    expect(sheetBottom - lastOptionBottom, lessThan(80));
  });
}
