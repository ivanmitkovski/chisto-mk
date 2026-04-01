import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorView', () {
    testWidgets('renders error message', (WidgetTester tester) async {
      const errorMessage = 'Something went wrong';

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorView(
              error: AppError(
                code: 'ERR',
                message: errorMessage,
              ),
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('shows retry button for retryable errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorView(
              error: AppError.network(),
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('hides retry button for non-retryable errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorView(
              error: AppError.unauthorized(),
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Try again'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('onRetry callback fires', (WidgetTester tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorView(
              error: AppError.network(),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });
  });
}
