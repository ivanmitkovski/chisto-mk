import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/new_report_stage_shell.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Widget _wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  group('NewReportStageScrollBody', () {
    testWidgets('renders child without banner when apiError is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          NewReportStageScrollBody(
            currentStage: ReportStage.details,
            apiError: null,
            onDismissApiError: () {},
            onRetryApiError: () {},
            child: const Text('stage body'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('stage body'), findsOneWidget);
      expect(find.byType(ApiErrorBanner), findsNothing);
    });

    testWidgets('shows retryable api error banner above child', (
      WidgetTester tester,
    ) async {
      var dismissed = false;
      var retried = false;

      await tester.pumpWidget(
        _wrap(
          NewReportStageScrollBody(
            currentStage: ReportStage.location,
            apiError: AppError.network(message: 'Network down'),
            onDismissApiError: () => dismissed = true,
            onRetryApiError: () => retried = true,
            child: const Text('stage body'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ApiErrorBanner), findsOneWidget);
      // The banner localizes by error code and never shows raw messages.
      expect(
        find.text('Please check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('Your draft is saved'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });
  });

  group('NewReportStageSurface', () {
    testWidgets('shows stage info title and child content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          NewReportStageSurface(
            stage: ReportStage.evidence,
            isHighlighted: false,
            reportFlowPrefsLoaded: false,
            hasSeenReportHelpHint: true,
            onDismissFlowHelpHint: () {},
            onPressedHelp: () {},
            child: const Text('evidence widgets'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('evidence widgets'), findsOneWidget);
    });

    testWidgets('shows flow help hint on evidence stage when not dismissed', (
      WidgetTester tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        _wrap(
          NewReportStageSurface(
            stage: ReportStage.evidence,
            isHighlighted: false,
            reportFlowPrefsLoaded: true,
            hasSeenReportHelpHint: false,
            onDismissFlowHelpHint: () => dismissed = true,
            onPressedHelp: () {},
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('Tap the info button for tips'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });

    testWidgets('invokes help callback from info button', (
      WidgetTester tester,
    ) async {
      var helpPressed = false;

      await tester.pumpWidget(
        _wrap(
          NewReportStageSurface(
            stage: ReportStage.review,
            isHighlighted: true,
            reportFlowPrefsLoaded: true,
            hasSeenReportHelpHint: true,
            onDismissFlowHelpHint: () {},
            onPressedHelp: () => helpPressed = true,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      expect(helpPressed, isTrue);
    });
  });
}
