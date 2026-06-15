import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_volunteer_cap_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

const Size _surfaceSize = Size(390, 844);
const double _keyboardInset = 300;

Widget _wrapVolunteerCapPicker({required double keyboardInset}) {
  return wrapForWidgetTest(
    MediaQuery(
      data: MediaQueryData(
        size: _surfaceSize,
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: Builder(
        builder: (BuildContext context) {
          Widget sheet = wrapScrollControlledBottomSheet(
            context: context,
            maxHeight: _surfaceSize.height * 0.88,
            keyboardInsetMode: SheetKeyboardInsetMode.lift,
            child: CreateEventVolunteerCapPickerSheet(
              initial: 30,
              onApply: (_) {},
            ),
          );
          return Align(
            alignment: Alignment.bottomCenter,
            child: sheet,
          );
        },
      ),
    ),
  );
}

void main() {
  setUpAll(bootstrapWidgetTests);

  testWidgets('custom volunteer cap field and Apply stay above keyboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(_wrapVolunteerCapPicker(keyboardInset: _keyboardInset));
    await tester.pumpAndSettle();

    expect(find.text('Volunteer cap'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);

    final Finder applyCta = find.text('Apply');
    expect(applyCta, findsOneWidget);

    final Finder customLabel = find.text('Custom');
    await tester.dragUntilVisible(
      customLabel,
      find.byType(Scrollable).last,
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    final Finder customField = find.byType(TextField);
    expect(customField, findsOneWidget);
    await tester.tap(customField);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    final double keyboardTop = _surfaceSize.height - _keyboardInset;
    expect(
      tester.getRect(applyCta).bottom,
      lessThan(keyboardTop),
      reason: 'Apply footer should sit above the keyboard',
    );
    if (customField.evaluate().isNotEmpty) {
      expect(
        tester.getRect(customField).bottom,
        lessThan(keyboardTop),
        reason: 'Custom cap field should stay above the keyboard',
      );
    }
  });

  testWidgets('Apply with No limit selected does not require custom value', (
    WidgetTester tester,
  ) async {
    int? applied;

    await tester.pumpWidget(
      wrapForWidgetTest(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CreateEventVolunteerCapPickerSheet(
            initial: null,
            onApply: (int? value) => applied = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No limit'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(applied, isNull);
    expect(find.textContaining('Enter a whole number'), findsNothing);
  });

  testWidgets('Apply validates custom only when custom field has text', (
    WidgetTester tester,
  ) async {
    int? applied;

    await tester.pumpWidget(
      wrapForWidgetTest(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CreateEventVolunteerCapPickerSheet(
            initial: 30,
            onApply: (int? value) => applied = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(applied, 30);
    expect(find.textContaining('Enter a whole number'), findsNothing);
  });
}
