import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_blocked_users_screen.dart';
import 'package:chisto_mobile/features/safety/data/ugc_moderation_repository.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

class _BlocksApiClient extends ApiClient {
  _BlocksApiClient({required this.body})
      : super(
          config: AppConfig.dev,
          accessToken: () => 'token',
          onUnauthorized: () {},
        );

  final String body;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    return ApiResponse(statusCode: 200, body: body);
  }
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows tokenized empty state when no blocks', (tester) async {
    final UgcModerationRepository repo = UgcModerationRepository(
      client: _BlocksApiClient(body: '[]'),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: ProfileBlockedUsersScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You have not blocked anyone.'), findsOneWidget);
    expect(find.textContaining('Block someone from event chat'), findsOneWidget);
  });

  testWidgets('lists blocked users with unblock action', (tester) async {
    final UgcModerationRepository repo = UgcModerationRepository(
      client: _BlocksApiClient(
        body:
            '[{"blockedUserId":"u-peer","blocked":{"id":"u-peer","firstName":"Peer","lastName":"User"}}]',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: ProfileBlockedUsersScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peer User'), findsOneWidget);
    expect(find.text('Unblock'), findsOneWidget);
  });
}
