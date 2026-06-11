import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_sheet_drag.dart';
import 'package:flutter/material.dart';

export 'package:feature_home/src/presentation/widgets/comments/comments_sheet_drag.dart'
    show
        CommentsSheetSizeConfig,
        kCommentsSheetInitialSize,
        kCommentsSheetMaxSize,
        kCommentsSheetMinSize,
        kCommentsSheetSnapSizes;

/// Shared modal chrome for site comments (feed cards + site detail).
Future<void> showPollutionSiteCommentsModalBottomSheet(
  BuildContext context, {
  required Widget Function(
    BuildContext sheetContext,
    ScrollController scrollController,
    DraggableScrollableController sheetController,
    CommentsSheetSizeConfig sizeConfig,
  )
  builder,
}) {
  return AppBottomSheet.showResizable<void>(
    context: context,
    sizeConfig: AppSheetSizeConfig(
      minSize: kCommentsSheetMinSize,
      maxSize: kCommentsSheetMaxSize,
      snapSizes: kCommentsSheetSnapSizes,
      initialSize: kCommentsSheetInitialSize,
    ),
    builder:
        (
          BuildContext sheetContext,
          ScrollController scrollController,
          DraggableScrollableController sheetController,
          AppSheetSizeConfig sizeConfig,
        ) {
          final CommentsSheetSizeConfig commentsConfig = CommentsSheetSizeConfig(
            minSize: sizeConfig.minSize,
            maxSize: sizeConfig.maxSize,
            snapSizes: sizeConfig.snapSizes,
          );
          return builder(
            sheetContext,
            scrollController,
            sheetController,
            commentsConfig,
          );
        },
  );
}
