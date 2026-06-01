import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Drag handle, title, and optional site line for the comments sheet.
class CommentsBottomSheetHeader extends StatelessWidget {
  const CommentsBottomSheetHeader({super.key, this.siteTitle});

  final String? siteTitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    void maybeClose() {
      Navigator.of(context).maybePop();
    }

    return Padding(
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            onVerticalDragEnd: (DragEndDetails details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 200) {
                maybeClose();
              }
            },
            child: Center(
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.commentsFeedHeaderTitle,
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
  }
}
