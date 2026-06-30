import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

class _BlockTestApiClient extends ApiClient {
  _BlockTestApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => 'token',
        onUnauthorized: (_) {},
      );

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    return const ApiResponse(
      statusCode: 201,
      json: <String, dynamic>{'id': 'blk1'},
    );
  }
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('confirmAndBlockUser posts block and shows success snack', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    await confirmAndBlockUser(
                      context,
                      blockedUserId: 'u-peer',
                      displayName: 'Peer User',
                      repository: UgcModerationRepository(
                        client: _BlockTestApiClient(),
                      ),
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
