import 'package:chisto_infrastructure/core/navigation/app_navigator_key.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppSnack resolves host context from root navigator in modal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appRootNavigatorKey,
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      builder: (BuildContext sheetContext) {
                        return Material(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: ElevatedButton(
                              onPressed: () {
                                AppSnack.show(
                                  sheetContext,
                                  message: 'Saved from modal',
                                  type: AppSnackType.success,
                                );
                              },
                              child: const Text('Show snack'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Open sheet'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show snack'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Saved from modal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}
