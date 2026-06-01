import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_localization/core/l10n/app_language_picker_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LanguagePickerOptionRow shows check when selected', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguagePickerOptionRow(
            label: 'English',
            selected: true,
            onTap: () => tapped = true,
            showDividerBelow: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('English'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('English'));
    expect(tapped, isTrue);
  });

  testWidgets('LanguagePickerOptionRow shows divider when requested', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguagePickerOptionRow(
            label: 'Macedonian',
            selected: false,
            onTap: () {},
            showDividerBelow: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Divider), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('AppLanguagePickerList marks current locale and calls onSelect', (
    WidgetTester tester,
  ) async {
    Locale? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: AppLanguagePickerList(
            current: const Locale('mk'),
            onSelect: (Locale? locale) async {
              selected = locale;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Use device language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Македонски'), findsOneWidget);
    expect(find.text('Shqip'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(selected, const Locale('en'));

    await tester.tap(find.text('Use device language'));
    await tester.pump();
    expect(selected, isNull);
  });
}
