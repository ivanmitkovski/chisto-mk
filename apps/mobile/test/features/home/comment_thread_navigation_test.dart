import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/presentation/utils/comment_thread_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

Comment _comment({
  required String id,
  String? authorId,
  String? parentId,
  DateTime? createdAt,
  List<Comment> replies = const <Comment>[],
}) {
  return Comment(
    id: id,
    authorId: authorId,
    authorName: 'User',
    text: 'text',
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    parentId: parentId,
    replies: replies,
  );
}

void main() {
  group('findCommentAncestorIds', () {
    test('returns parent ids for nested reply', () {
      final List<Comment> comments = <Comment>[
        _comment(
          id: 'root',
          replies: <Comment>[
            _comment(id: 'reply', parentId: 'root', replies: <Comment>[
              _comment(id: 'nested', parentId: 'reply'),
            ]),
          ],
        ),
      ];

      expect(findCommentAncestorIds(comments, 'nested'), <String>['root', 'reply']);
    });

    test('returns empty list for root comment', () {
      final List<Comment> comments = <Comment>[
        _comment(id: 'root'),
      ];
      expect(findCommentAncestorIds(comments, 'root'), isEmpty);
    });
  });

  group('resolveHighlightCommentId', () {
    test('prefers explicit commentId', () {
      final List<Comment> comments = <Comment>[
        _comment(id: 'c1', authorId: 'u1'),
      ];
      expect(
        resolveHighlightCommentId(
          comments: comments,
          commentId: 'c1',
          actorUserId: 'u2',
        ),
        'c1',
      );
    });

    test('falls back to newest root comment by actor', () {
      final List<Comment> comments = <Comment>[
        _comment(
          id: 'old',
          authorId: 'actor',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        _comment(
          id: 'new',
          authorId: 'actor',
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      ];
      expect(
        resolveHighlightCommentId(
          comments: comments,
          actorUserId: 'actor',
        ),
        'new',
      );
    });
  });

  group('flattenedCommentIndex', () {
    test('finds index after ancestors expanded', () {
      final List<Comment> comments = <Comment>[
        _comment(
          id: 'root',
          replies: <Comment>[
            _comment(id: 'child', parentId: 'root'),
          ],
        ),
      ];
      final int? index = flattenedCommentIndex(
        comments,
        <String>{'root'},
        'child',
      );
      expect(index, 1);
    });
  });
}
