// Manual QA matrix (site comments): long thread + load more; reply with keyboard open;
// rotate device; VoiceOver / TalkBack order; rate limit / slow network; cancel edit mid-flight;
// pull-to-refresh on full-screen route; sort change while offline.

import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments_bottom_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime commentTime = DateTime.utc(2026, 1, 10, 15);

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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: CommentsBottomSheet(comments: comments),
        ),
      ),
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

  testWidgets('inserts reply under parent and keeps it visible', (tester) async {
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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: CommentsBottomSheet(
            comments: comments,
            onCommentsChanged: (value) => latestComments = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '@Ivan Mitkovski Child reply');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: CommentsBottomSheet(
            comments: comments,
            onCommentEdited: (commentId, body) async {
              editedBody = body;
            },
          ),
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

  testWidgets('deletes comment directly from actions sheet', (tester) async {
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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: CommentsBottomSheet(
            comments: comments,
            onCommentDeleted: (commentId) async {
              deletedId = commentId;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete comment'));
    await tester.pumpAndSettle();

    expect(deletedId, 'c1');
  });
}
