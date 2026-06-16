// Manual QA matrix (site comments): long thread + load more; reply with keyboard open;
// rotate device; VoiceOver / TalkBack order; rate limit / slow network; cancel edit mid-flight;
// pull-to-refresh on full-screen route; sort change while offline.

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/presentation/widgets/comments_bottom_sheet.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UgcTestApiClient extends ApiClient {
  _UgcTestApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    return const ApiResponse(statusCode: 204, json: null);
  }
}

AuthState _testAuthState({String displayName = 'Ivan Mitkovski'}) {
  final AuthState state = AuthState();
  state.setAuthenticated(userId: 'u-test', displayName: displayName);
  return state;
}

Widget _wrapCommentsTest(Widget child) {
  return ProviderScope(
    overrides: <Override>[
      authStateProvider.overrideWith((Ref ref) => _testAuthState()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  final DateTime commentTime = DateTime.utc(2026, 1, 10, 15);

  testWidgets('non-owned comment menu offers report and block', (tester) async {
    final UgcModerationRepository ugcTestRepo = UgcModerationRepository(
      client: _UgcTestApiClient(),
    );
    final comments = <Comment>[
      Comment(
        id: 'c-peer',
        authorId: 'u-peer',
        authorName: 'Peer User',
        text: 'Needs cleanup here',
        createdAt: commentTime,
        isOwnedByMe: false,
      ),
    ];

    await tester.pumpWidget(
      _wrapCommentsTest(
        CommentsBottomSheet(
          comments: comments,
          ugcModerationRepository: ugcTestRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Report content'), findsOneWidget);
    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('Edit comment'), findsNothing);
  });

  testWidgets('clears draft when reply mode is cancelled', (tester) async {
    final comments = <Comment>[
      Comment(
        id: 'c1',
        authorName: 'Ivan Mitkovski',
        text: 'Lets clean it',
        createdAt: commentTime,
      ),
    ];

    await tester.pumpWidget(
      _wrapCommentsTest(CommentsBottomSheet(comments: comments)),
    );

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '@Ivan Mitkovski test');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text ?? '', isEmpty);
  });

  testWidgets('inserts reply under parent and keeps it visible', (
    tester,
  ) async {
    final comments = <Comment>[
      Comment(
        id: 'c1',
        authorName: 'Ivan Mitkovski',
        text: 'Lets clean it',
        createdAt: commentTime,
      ),
    ];
    List<Comment>? latestComments;

    await tester.pumpWidget(
      _wrapCommentsTest(
        CommentsBottomSheet(
          comments: comments,
          onCommentsChanged: (value) => latestComments = value,
        ),
      ),
    );

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '@Ivan Mitkovski Child reply',
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(latestComments, isNotNull);
    expect(latestComments!.first.replies.length, 1);
    expect(latestComments!.first.replies.first.parentId, 'c1');
  });

  testWidgets('edits comment inline in composer and saves', (tester) async {
    final comments = <Comment>[
      Comment(
        id: 'c1',
        authorName: 'Ivan Mitkovski',
        text: '@Ivan Mitkovski test',
        createdAt: commentTime,
        isOwnedByMe: true,
      ),
    ];
    String? editedBody;

    await tester.pumpWidget(
      _wrapCommentsTest(
        CommentsBottomSheet(
          comments: comments,
          onCommentEdited: (commentId, body) async {
            editedBody = body;
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit comment'));
    await tester.pumpAndSettle();

    expect(find.text('Editing comment'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '@Ivan Mitkovski updated');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(editedBody, '@Ivan Mitkovski updated');
  });

  testWidgets('deletes comment after confirmation dialog', (tester) async {
    final comments = <Comment>[
      Comment(
        id: 'c1',
        authorName: 'Ivan Mitkovski',
        text: 'Will delete',
        createdAt: commentTime,
        isOwnedByMe: true,
      ),
    ];
    String? deletedId;

    await tester.pumpWidget(
      _wrapCommentsTest(
        CommentsBottomSheet(
          comments: comments,
          onCommentDeleted: (commentId) async {
            deletedId = commentId;
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete comment'));
    await tester.pumpAndSettle();

    expect(find.text('Delete comment'), findsWidgets);
    expect(
      find.text(
        "Your comment will be permanently removed from this thread. This can't be undone.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deletedId, 'c1');
  });

  testWidgets('does not delete comment when confirmation is cancelled', (
    tester,
  ) async {
    final comments = <Comment>[
      Comment(
        id: 'c1',
        authorName: 'Ivan Mitkovski',
        text: 'Keep me',
        createdAt: commentTime,
        isOwnedByMe: true,
      ),
    ];
    String? deletedId;

    await tester.pumpWidget(
      _wrapCommentsTest(
        CommentsBottomSheet(
          comments: comments,
          onCommentDeleted: (commentId) async {
            deletedId = commentId;
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deletedId, isNull);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
  });

  testWidgets('posts comment within max length optimistically', (tester) async {
    final comments = <Comment>[];
    List<Comment>? latestComments;
    final String body = 'a' * 400;

    await tester.pumpWidget(
      _wrapCommentsTest(
        CommentsBottomSheet(
          comments: comments,
          onCommentsChanged: (value) => latestComments = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), body);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(latestComments, isNotNull);
    expect(latestComments!.length, 1);
    expect(latestComments!.first.text, body);
  });

  testWidgets('does not post whitespace-only comment', (tester) async {
    final comments = <Comment>[];
    List<Comment>? latestComments;

    await tester.pumpWidget(
      _wrapCommentsTest(
        CommentsBottomSheet(
          comments: comments,
          onCommentsChanged: (value) => latestComments = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(latestComments ?? comments, isEmpty);
  });
}
