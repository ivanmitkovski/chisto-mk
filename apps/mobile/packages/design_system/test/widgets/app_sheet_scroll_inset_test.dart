import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wrap merges bottom padding into SingleChildScrollView', (
    WidgetTester tester,
  ) async {
    const double inset = 34;

    await tester.pumpWidget(
      MaterialApp(
        home: AppSheetScrollInset.wrap(
          bottom: inset,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: const SizedBox(height: 100),
          ),
        ),
      ),
    );

    final SingleChildScrollView scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(
      scroll.padding?.resolve(TextDirection.ltr).bottom,
      AppSpacing.sm + inset,
    );
  });

  testWidgets('wrap merges bottom padding into ListView.builder', (
    WidgetTester tester,
  ) async {
    const double inset = 34;

    await tester.pumpWidget(
      MaterialApp(
        home: AppSheetScrollInset.wrap(
          bottom: inset,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            itemCount: 1,
            itemBuilder: (BuildContext context, int index) {
              return const Text('Row');
            },
          ),
        ),
      ),
    );

    final ListView listView = tester.widget<ListView>(find.byType(ListView));
    expect(
      listView.padding?.resolve(TextDirection.ltr).bottom,
      AppSpacing.xs + inset,
    );
  });

  testWidgets('AppSheetScrollInsets.of returns inherited value', (
    WidgetTester tester,
  ) async {
    const double inset = 28;
    late double readInset;

    await tester.pumpWidget(
      MaterialApp(
        home: AppSheetScrollInsets(
          scrollBottom: inset,
          child: Builder(
            builder: (BuildContext context) {
              readInset = AppSheetScrollInsets.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(readInset, inset);
  });
}
