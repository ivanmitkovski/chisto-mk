import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sizes modal to content instead of filling the screen', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, screenHeight),
            padding: EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: EdgeInsets.only(top: 59, bottom: 34),
          ),
          child: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showAppGroupedOptionPicker<String>(
                        context: context,
                        title: 'Choose category',
                        subtitle: 'Pick the closest match.',
                        options: const <AppGroupedOption<String>>[
                          AppGroupedOption<String>(
                            icon: Icons.delete,
                            title: 'Illegal landfill',
                            subtitle: 'Dumped waste or trash piles.',
                            value: 'landfill',
                          ),
                          AppGroupedOption<String>(
                            icon: Icons.water,
                            title: 'Water pollution',
                            subtitle: 'Contaminated rivers or lakes.',
                            value: 'water',
                          ),
                          AppGroupedOption<String>(
                            icon: Icons.air,
                            title: 'Air pollution',
                            subtitle: 'Smoke, dust, or burning waste.',
                            value: 'air',
                          ),
                          AppGroupedOption<String>(
                            icon: Icons.factory,
                            title: 'Industrial waste',
                            subtitle: 'Construction or factory waste.',
                            value: 'industrial',
                          ),
                          AppGroupedOption<String>(
                            icon: Icons.more_horiz,
                            title: 'Other',
                            subtitle: 'Use when nothing else fits.',
                            value: 'other',
                          ),
                        ],
                        isSelected: (_) => false,
                        onOptionTap: (_) {},
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final RenderBox sheetBox = tester.renderObject<RenderBox>(
      find.byType(AppSheetScaffold),
    );

    expect(sheetBox.size.height, lessThan(screenHeight * 0.75));
    expect(sheetBox.size.height, greaterThan(420));

    final RenderBox lastOptionBox = tester.renderObject<RenderBox>(
      find.text('Other'),
    );
    final double sheetBottom = sheetBox.localToGlobal(Offset.zero).dy +
        sheetBox.size.height;
    final double lastOptionBottom = lastOptionBox.localToGlobal(Offset.zero).dy +
        lastOptionBox.size.height;
    expect(
      sheetBottom - lastOptionBottom,
      lessThan(80),
      reason: 'Sheet should hug content with only chrome + home-indicator inset',
    );
    expect(
      sheetBox.localToGlobal(Offset.zero).dy,
      greaterThan(59),
      reason: 'Sheet top should stay below the status bar / notch',
    );
  });

  testWidgets('renders grouped options with optional instruction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppGroupedOptionPickerSheet<String>(
            title: 'Pick one',
            subtitle: 'Choose an option',
            instructionMessage: 'Helper copy for moderators.',
            options: const <AppGroupedOption<String>>[
              AppGroupedOption<String>(
                icon: Icons.delete,
                title: 'Landfill',
                subtitle: 'Illegal dump site',
                value: 'landfill',
              ),
              AppGroupedOption<String>(
                icon: Icons.water,
                title: 'Water',
                value: 'water',
              ),
            ],
            isSelected: (String value) => value == 'landfill',
            onOptionTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Pick one'), findsOneWidget);
    expect(find.text('Choose an option'), findsOneWidget);
    expect(find.text('Helper copy for moderators.'), findsOneWidget);
    expect(find.byType(AppGroupedActionList), findsOneWidget);
    expect(find.text('Landfill'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
  });

  testWidgets('custom trailing builder is used when provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppGroupedOptionPickerSheet<int>(
            title: 'Difficulty',
            options: const <AppGroupedOption<int>>[
              AppGroupedOption<int>(
                icon: Icons.shield,
                title: 'Easy',
                value: 1,
              ),
            ],
            isSelected: (_) => true,
            onOptionTap: (_) {},
            trailingBuilder: (_, __) => const SizedBox(
              key: Key('custom_trailing'),
              width: 10,
              height: 10,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('custom_trailing')), findsOneWidget);
  });
}
