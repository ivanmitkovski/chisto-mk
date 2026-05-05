import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_comments_engagement_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('commentCountForEngagementAfterFetch', () {
    final DateTime t = DateTime.utc(2026, 1, 1);

    test('uses max of API root total and full thread when roots meta understates replies',
        () {
      final List<Comment> tree = <Comment>[
        Comment(
          id: '1',
          authorName: 'A',
          text: 'r',
          createdAt: t,
          replies: <Comment>[
            Comment(
              id: '2',
              authorName: 'B',
              text: 'a',
              createdAt: t,
              parentId: '1',
            ),
            Comment(
              id: '3',
              authorName: 'C',
              text: 'b',
              createdAt: t,
              parentId: '1',
            ),
          ],
        ),
      ];
      const SiteCommentsResult result = SiteCommentsResult(
        items: <SiteCommentItem>[],
        page: 1,
        limit: 20,
        total: 1,
      );
      expect(
        commentCountForEngagementAfterFetch(
          result: result,
          mappedComments: tree,
        ),
        3,
      );
    });
  });
}
