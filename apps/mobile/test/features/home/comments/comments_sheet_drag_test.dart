import 'package:feature_home/src/presentation/widgets/comments/comments_sheet_drag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const double minSize = kCommentsSheetMinSize;
  const double maxSize = kCommentsSheetMaxSize;
  const List<double> snapSizes = kCommentsSheetSnapSizes;

  group('sheetSizeAfterDrag', () {
    test('downward delta shrinks the sheet', () {
      expect(
        sheetSizeAfterDrag(
          size: 0.74,
          deltaSize: 0.1,
          minSize: minSize,
          maxSize: maxSize,
        ),
        0.64,
      );
    });

    test('upward delta grows the sheet', () {
      expect(
        sheetSizeAfterDrag(
          size: 0.74,
          deltaSize: -0.1,
          minSize: minSize,
          maxSize: maxSize,
        ),
        0.84,
      );
    });

    test('clamps to min and max', () {
      expect(
        sheetSizeAfterDrag(
          size: 0.6,
          deltaSize: 0.2,
          minSize: minSize,
          maxSize: maxSize,
        ),
        minSize,
      );
      expect(
        sheetSizeAfterDrag(
          size: 0.9,
          deltaSize: -0.2,
          minSize: minSize,
          maxSize: maxSize,
        ),
        maxSize,
      );
    });
  });

  group('resolveSheetDragEnd', () {
    CommentsSheetDragEndResult resolve({
      required double size,
      double? velocity,
    }) {
      return resolveSheetDragEnd(
        size: size,
        velocity: velocity,
        minSize: minSize,
        maxSize: maxSize,
        snapSizes: snapSizes,
      );
    }

    test('slow drag snaps to nearest candidate', () {
      final CommentsSheetDragEndResult result = resolve(
        size: 0.8,
        velocity: 50,
      );
      expect(result.action, CommentsSheetDragEndAction.animateTo);
      expect(result.targetSize, 0.74);
    });

    test('downward fling at min dismisses', () {
      final CommentsSheetDragEndResult result = resolve(
        size: minSize,
        velocity: kCommentsSheetFlingVelocity + 1,
      );
      expect(result.action, CommentsSheetDragEndAction.dismiss);
    });

    test('downward fling above min snaps to next lower size', () {
      final CommentsSheetDragEndResult result = resolve(
        size: 0.8,
        velocity: kCommentsSheetFlingVelocity + 1,
      );
      expect(result.action, CommentsSheetDragEndAction.animateTo);
      expect(result.targetSize, 0.74);
    });

    test('upward fling snaps to next higher size', () {
      final CommentsSheetDragEndResult result = resolve(
        size: 0.8,
        velocity: -kCommentsSheetFlingVelocity - 1,
      );
      expect(result.action, CommentsSheetDragEndAction.animateTo);
      expect(result.targetSize, maxSize);
    });

    test('legacy fast flick near min dismisses', () {
      final CommentsSheetDragEndResult result = resolve(
        size: minSize + 0.02,
        velocity: kCommentsSheetLegacyDismissVelocity + 1,
      );
      expect(result.action, CommentsSheetDragEndAction.dismiss);
    });
  });
}
