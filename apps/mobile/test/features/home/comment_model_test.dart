import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Comment', () {
    final DateTime t = DateTime.utc(2026, 2, 1, 8);

    test('constructs with required fields', () {
      final Comment comment = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Great post!',
        createdAt: t,
      );

      expect(comment.id, 'c1');
      expect(comment.authorName, 'Alice');
      expect(comment.text, 'Great post!');
      expect(comment.createdAt, t);
      expect(comment.likeCount, 0);
      expect(comment.isLikedByMe, false);
    });

    test('constructs with optional fields', () {
      final Comment comment = Comment(
        id: 'c2',
        authorName: 'Bob',
        text: 'Nice work',
        createdAt: t,
        likeCount: 5,
        isLikedByMe: true,
      );

      expect(comment.likeCount, 5);
      expect(comment.isLikedByMe, true);
    });

    test('copyWith produces new instance with updated fields', () {
      final Comment original = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Original',
        createdAt: t,
        likeCount: 2,
        isLikedByMe: false,
      );

      final Comment updated = original.copyWith(
        text: 'Updated',
        likeCount: 3,
        isLikedByMe: true,
      );

      expect(updated.id, 'c1');
      expect(updated.authorName, 'Alice');
      expect(updated.text, 'Updated');
      expect(updated.createdAt, t);
      expect(updated.likeCount, 3);
      expect(updated.isLikedByMe, true);
    });

    test('copyWith preserves unchanged fields', () {
      final Comment original = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Original',
        createdAt: t,
        likeCount: 2,
        isLikedByMe: false,
      );

      final Comment updated = original.copyWith(text: 'Updated');

      expect(updated.id, 'c1');
      expect(updated.authorName, 'Alice');
      expect(updated.text, 'Updated');
      expect(updated.likeCount, 2);
      expect(updated.isLikedByMe, false);
    });

    test('copyWith preserves original values when null passed for optional fields', () {
      final Comment original = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Text',
        createdAt: t,
        likeCount: 5,
        isLikedByMe: true,
      );

      final Comment same = original.copyWith(
        likeCount: null,
        isLikedByMe: null,
      );

      expect(same.likeCount, 5);
      expect(same.isLikedByMe, true);
    });
  });
}
