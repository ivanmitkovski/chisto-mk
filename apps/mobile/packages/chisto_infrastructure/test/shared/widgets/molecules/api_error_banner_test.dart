import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ApiErrorBanner announces retryable network error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ApiErrorBanner(error: AppError.network(), onRetry: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(ApiErrorBanner), findsOneWidget);
  });
}
