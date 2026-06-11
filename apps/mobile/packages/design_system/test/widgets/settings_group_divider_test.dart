import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsGroupDivider renders a single full-width hairline segment', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SettingsGroupDivider(),
          ),
        ),
      ),
    );

    final Finder dividerRow = find.byType(SettingsGroupDivider);
    expect(dividerRow, findsOneWidget);

    final RenderBox rowBox = tester.renderObject<RenderBox>(
      find.descendant(
        of: dividerRow,
        matching: find.byType(Row),
      ),
    );
    final RenderBox hairlineBox = tester.renderObject<RenderBox>(
      find.descendant(
        of: dividerRow,
        matching: find.byType(ColoredBox),
      ),
    );

    expect(hairlineBox.size.width, rowBox.size.width - SettingsGroupDivider.leadingInset);
    expect(hairlineBox.size.height, 1);
  });

  testWidgets('SettingsListTile omits divider on last row when showDividerBelow is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SettingsListTile(
            leadingIcon: Icons.help_outline_rounded,
            title: 'Центар за помош',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(SettingsGroupDivider), findsNothing);
  });
}
