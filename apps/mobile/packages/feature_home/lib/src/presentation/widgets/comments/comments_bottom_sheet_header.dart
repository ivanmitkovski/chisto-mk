import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_sheet_drag.dart';
import 'package:flutter/material.dart';

/// Drag handle, title, and optional site line for the comments sheet.
class CommentsBottomSheetHeader extends StatelessWidget {
  const CommentsBottomSheetHeader({
    super.key,
    this.siteTitle,
    this.commentCount,
    this.sheetController,
    this.sizeConfig = CommentsSheetSizeConfig.standard,
  });

  final String? siteTitle;
  final int? commentCount;
  final DraggableScrollableController? sheetController;
  final CommentsSheetSizeConfig sizeConfig;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final DraggableScrollableController? controller = sheetController;
    final double? primaryDelta = details.primaryDelta;
    if (controller == null ||
        !controller.isAttached ||
        primaryDelta == null) {
      return;
    }
    final double deltaSize = controller.pixelsToSize(primaryDelta);
    final double nextSize = sheetSizeAfterDrag(
      size: controller.size,
      deltaSize: deltaSize,
      minSize: sizeConfig.minSize,
      maxSize: sizeConfig.maxSize,
    );
    controller.jumpTo(nextSize);
  }

  void _onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    final DraggableScrollableController? controller = sheetController;
    if (controller == null || !controller.isAttached) {
      return;
    }
    final CommentsSheetDragEndResult result = resolveSheetDragEnd(
      size: controller.size,
      velocity: details.primaryVelocity,
      minSize: sizeConfig.minSize,
      maxSize: sizeConfig.maxSize,
      snapSizes: sizeConfig.snapSizes,
    );
    switch (result.action) {
      case CommentsSheetDragEndAction.animateTo:
        controller.animateTo(
          result.targetSize!,
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        );
      case CommentsSheetDragEndAction.dismiss:
        Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DraggableScrollableController? controller = sheetController;
    final bool draggable = controller != null;

    final Widget headerContent = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Semantics(
              label: context.l10n.commentsSemanticSheetDragHandle,
              child: Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            commentCount != null
                ? '${context.l10n.commentsFeedHeaderTitle} · $commentCount'
                : context.l10n.commentsFeedHeaderTitle,
            style: AppTypography.sheetTitle(
              textTheme,
            ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (siteTitle != null && siteTitle!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              siteTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardSubtitle(
                textTheme,
              ).copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );

    if (!draggable) {
      return headerContent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: (DragEndDetails details) =>
          _onVerticalDragEnd(context, details),
      child: headerContent,
    );
  }
}
