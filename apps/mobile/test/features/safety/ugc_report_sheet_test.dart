import 'dart:async';

import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

class _ReportApiClient extends ApiClient {
  _ReportApiClient({this.fail = false})
    : super(
        config: AppConfig.dev,
        accessToken: () => 'token',
        onUnauthorized: () {},
      );

  final bool fail;
  Object? lastBody;

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    lastBody = body;
    if (fail) {
      throw StateError('network');
    }
    return const ApiResponse(
      statusCode: 201,
      json: <String, dynamic>{'id': 'rep1'},
    );
  }
}

Future<void> _openReportSheet(
  WidgetTester tester, {
  required UgcModerationRepository repository,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  unawaited(
                    showUgcReportSheet(
                      context,
                      subjectType: 'user',
                      subjectId: 'u-peer',
                      repository: repository,
                    ),
                  );
                },
                child: const Text('Open report'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open report'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('submits selected reason and shows success snack', (
    tester,
  ) async {
    final _ReportApiClient client = _ReportApiClient();
    final UgcModerationRepository repo = UgcModerationRepository(
      client: client,
    );

    await _openReportSheet(tester, repository: repo);

    expect(find.text('Report content'), findsOneWidget);
    await tester.tap(find.text('Harassment'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(client.lastBody, <String, dynamic>{
      'subjectType': 'user',
      'subjectId': 'u-peer',
      'reason': 'harassment',
    });
    expect(
      find.text('Report submitted. We review reports within 24 hours.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error snack when submit fails', (tester) async {
    final UgcModerationRepository repo = UgcModerationRepository(
      client: _ReportApiClient(fail: true),
    );

    await _openReportSheet(tester, repository: repo);

    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.text('Could not submit report. Try again.'), findsOneWidget);
  });

  testWidgets('double submit tap posts once', (tester) async {
    final _ReportApiClient client = _ReportApiClient();
    final UgcModerationRepository repo = UgcModerationRepository(
      client: client,
    );

    await _openReportSheet(tester, repository: repo);

    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(client.lastBody, isNotNull);
    expect(
      find.text('Report submitted. We review reports within 24 hours.'),
      findsOneWidget,
    );
  });
}
