import 'package:chisto_infrastructure/shared/widgets/atoms/app_search_query_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppSearchQueryChip renders label and responds to tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchQueryChip(
            label: 'Bitola landfill',
            highlightQuery: 'bit',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Bitola landfill'), findsOneWidget);

    await tester.tap(find.byType(AppSearchQueryChip));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AppSearchQueryChip exposes semantics label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchQueryChip(
            label: 'Skopje',
            semanticLabel: 'Search for Skopje',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AppSearchQueryChip)),
      matchesSemantics(isButton: true, label: 'Search for Skopje'),
    );
  });
}
