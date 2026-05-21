import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/safety/data/ugc_moderation_repository.dart';
import 'package:chisto_mobile/features/safety/presentation/block_user_flow.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

class _BlockTestApiClient extends ApiClient {
  _BlockTestApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => 'token',
          onUnauthorized: () {},
        );

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    return ApiResponse(statusCode: 201, json: <String, dynamic>{'id': 'blk1'});
  }
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('confirmAndBlockUser posts block and shows success snack', (tester) async {
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
                  onPressed: () async {
                    await confirmAndBlockUser(
                      context,
                      blockedUserId: 'u-peer',
                      displayName: 'Peer User',
                      repository: UgcModerationRepository(client: _BlockTestApiClient()),
                    );
                  },
                  child: const Text('Block'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();

    expect(find.text('Block user'), findsOneWidget);
    await tester.tap(find.text('Block').last);
    await tester.pumpAndSettle();

    expect(find.text('User blocked.'), findsOneWidget);
  });
}
