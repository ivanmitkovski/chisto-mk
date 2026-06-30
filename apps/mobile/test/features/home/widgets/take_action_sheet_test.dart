import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/take_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const List<LocalizationsDelegate<dynamic>> _delegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

const double _screenHeight = 844;

MaterialApp _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: _delegates,
    supportedLocales: const <Locale>[Locale('en')],
    home: Scaffold(body: child),
  );
}

Finder _takeActionSheetShell() {
  return find.ancestor(
    of: find.text('Take action'),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color ==
              AppColors.panelBackground,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TakeActionSheet', () {
    testWidgets('shows create, join and share actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const TakeActionSheet()));
      await tester.pumpAndSettle();

      expect(find.text('Create eco action'), findsOneWidget);
      expect(find.text('Join action'), findsOneWidget);
      expect(find.text('Share site'), findsOneWidget);
    });

    testWidgets('does not show donate action', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const TakeActionSheet()));
      await tester.pumpAndSettle();

      expect(find.text('Donate / contribute'), findsNothing);
    });

    testWidgets('real modal hugs content without full-screen host slab', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, _screenHeight));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _delegates,
          supportedLocales: const <Locale>[Locale('en')],
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      TakeActionSheet.show(context);
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_takeActionSheetShell(), findsOneWidget);
      expect(
        tester.getSize(_takeActionSheetShell()).height,
        lessThan(_screenHeight * 0.55),
        reason: 'Take action must not expand to a full-viewport white slab',
      );

      final Rect shareRect = tester.getRect(find.text('Share site'));
      final Rect sheetRect = tester.getRect(_takeActionSheetShell());
      expect(
        sheetRect.bottom - shareRect.bottom,
        lessThan(84),
        reason: 'Last action should sit near the sheet bottom',
      );
    });
  });
}
