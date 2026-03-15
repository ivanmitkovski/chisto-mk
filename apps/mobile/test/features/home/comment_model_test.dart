import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Comment', () {
    test('constructs with required fields', () {
      const Comment comment = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Great post!',
      );

      expect(comment.id, 'c1');
      expect(comment.authorName, 'Alice');
      expect(comment.text, 'Great post!');
      expect(comment.likeCount, 0);
      expect(comment.isLikedByMe, false);
    });

    test('constructs with optional fields', () {
      const Comment comment = Comment(
        id: 'c2',
        authorName: 'Bob',
        text: 'Nice work',
        likeCount: 5,
        isLikedByMe: true,
      );

      expect(comment.likeCount, 5);
      expect(comment.isLikedByMe, true);
    });

    test('copyWith produces new instance with updated fields', () {
      const Comment original = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Original',
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
      expect(updated.likeCount, 3);
      expect(updated.isLikedByMe, true);
    });

    test('copyWith preserves unchanged fields', () {
      const Comment original = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Original',
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
      const Comment original = Comment(
        id: 'c1',
        authorName: 'Alice',
        text: 'Text',
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
