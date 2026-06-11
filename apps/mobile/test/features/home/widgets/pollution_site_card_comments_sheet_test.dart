import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/widgets/comments_bottom_sheet.dart';
import 'package:feature_home/src/presentation/widgets/pollution_site_card_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/stub_sites_repository.dart';
import '../support/test_pollution_site.dart';

class _DelayedCommentsSitesRepository extends StubSitesRepository {
  _DelayedCommentsSitesRepository({required this.delay});

  final Duration delay;
  int getSiteCommentsCalls = 0;

  @override
  Future<SiteCommentsResult> getSiteComments(
    String id, {
    int page = 1,
    int limit = 20,
    String sort = 'top',
    String? parentId,
  }) async {
    getSiteCommentsCalls++;
    await Future<void>.delayed(delay);
    return const SiteCommentsResult(
      items: <SiteCommentItem>[],
      page: 1,
      limit: 20,
      total: 0,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rapid comment icon taps open only one comments sheet', (
    WidgetTester tester,
  ) async {
    final PollutionSite site = buildTestPollutionSite(id: 'site-a');
    final _DelayedCommentsSitesRepository repository =
        _DelayedCommentsSitesRepository(
          delay: const Duration(milliseconds: 120),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sitesRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith((Ref ref) {
            final AuthState state = AuthState();
            state.setAuthenticated(userId: 'u-test', displayName: 'Tester');
            return state;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      unawaited(
                        openPollutionSiteCardCommentsSheet(
                          context: context,
                          ref: ref,
                          site: site,
                          initialSessionComments: const <Comment>[],
                          onSessionCommentsReplaced: (_) {},
                          onSessionCommentsChanged: (_) {},
                          feedSessionId: null,
                          feedVariant: null,
                        ),
                      );
                      unawaited(
                        openPollutionSiteCardCommentsSheet(
                          context: context,
                          ref: ref,
                          site: site,
                          initialSessionComments: const <Comment>[],
                          onSessionCommentsReplaced: (_) {},
                          onSessionCommentsChanged: (_) {},
                          feedSessionId: null,
                          feedVariant: null,
                        ),
                      );
                    },
                    child: const Text('Open comments'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open comments'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byType(CommentsBottomSheet), findsOneWidget);
    expect(repository.getSiteCommentsCalls, 1);
  });
}
