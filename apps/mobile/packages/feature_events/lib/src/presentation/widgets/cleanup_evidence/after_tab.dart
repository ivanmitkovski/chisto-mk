import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AfterTab extends StatelessWidget {
  const AfterTab({
    super.key,
    required this.afterImages,
    required this.selectedIndex,
    required this.isPicking,
    required this.maxImages,
    required this.heroHeight,
    required this.thumbSize,
    required this.thumbStripHeight,
    required this.onPick,
    required this.onRemove,
    required this.onSelect,
    required this.onImageTap,
    required this.onThumbnailLongPress,
    required this.buildImage,
  });

  final List<String> afterImages;
  final int selectedIndex;
  final bool isPicking;
  final int maxImages;
  final double heroHeight;
  final double thumbSize;
  final double thumbStripHeight;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onImageTap;
  final ValueChanged<int> onThumbnailLongPress;
  final Widget Function(String path, {double? height, BoxFit fit}) buildImage;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (isPicking) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (afterImages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AddPhotosEmptyState(
          onTap: onPick,
          emptyTitle: context.l10n.eventsCleanupAfterEmptyTitle,
          emptyMaxPhotosLine: context.l10n.eventsCleanupAfterEmptyMaxPhotos(
            maxImages,
          ),
          emptyTapHint: context.l10n.eventsCleanupAfterEmptyTapGallery,
          semanticsLabel: context.l10n.eventsCleanupAfterUploadSemantic,
        ),
      );
    }

    final String selectedPath =
        afterImages[selectedIndex.clamp(0, afterImages.length - 1)];
    final int remaining = maxImages - afterImages.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Semantics(
                button: true,
                label: context.l10n.eventsCleanupAfterViewFullscreenSemantic,
                child: GestureDetector(
                  onTap: () => onImageTap(
                    selectedIndex.clamp(0, afterImages.length - 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: buildImage(selectedPath, height: heroHeight),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(
                    AppSpacing.sheetHandle,
                    AppSpacing.sheetHandle,
                  ),
                  onPressed: () =>
                      onRemove(selectedIndex.clamp(0, afterImages.length - 1)),
                  child: Container(
                    width: AppSpacing.avatarSm,
                    height: AppSpacing.avatarSm,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.eventsCleanupAfterUploadMoreTitle,
                  style: AppTypography.eventsPanelTitle(textTheme),
                ),
              ),
              Text(
                context.l10n.eventsCleanupAfterUploadedCount(
                  afterImages.length,
                ),
                style: AppTypography.eventsListCardMeta(textTheme),
              ),
            ],
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs / 2),
              child: Text(
                context.l10n.eventsCleanupAfterSlotsRemaining(remaining),
                style: AppTypography.eventsListCardMeta(textTheme),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: thumbStripHeight,
            child: Semantics(
              container: true,
              label: context.l10n.eventsCleanupEvidencePhotoSemantic,
              explicitChildNodes: true,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: afterImages.length + (remaining > 0 ? 1 : 0),
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0 && remaining > 0) {
                    return Semantics(
                      button: true,
                      label: context.l10n.eventsCleanupAfterAddMoreSemantic,
                      child: GestureDetector(
                        onTap: onPick,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.plus,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }
                  final int imageIndex = remaining > 0 ? index - 1 : index;
                  final String path = afterImages[imageIndex];
                  final bool isSelected = imageIndex == selectedIndex;
                  return GestureDetector(
                    onTap: () => onSelect(imageIndex),
                    onLongPress: () => onThumbnailLongPress(imageIndex),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radius10,
                            ),
                            child: SizedBox(
                              width: thumbSize,
                              height: thumbSize,
                              child: buildImage(
                                path,
                                height: thumbSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Semantics(
                            button: true,
                            label:
                                context.l10n.eventsCleanupAfterRemoveSemantic,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(24, 24),
                              onPressed: () => onRemove(imageIndex),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.panelBackground,
                                  shape: BoxShape.circle,
                                  boxShadow:
                                      AppShadows.cleanupEvidenceThumbnail(),
                                ),
                                child: const Icon(
                                  CupertinoIcons.minus_circle_fill,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPhotosEmptyState extends StatelessWidget {
  const AddPhotosEmptyState({
    super.key,
    required this.onTap,
    required this.emptyTitle,
    required this.emptyMaxPhotosLine,
    required this.emptyTapHint,
    this.semanticsLabel,
  });

  final VoidCallback onTap;
  final String emptyTitle;
  final String emptyMaxPhotosLine;
  final String emptyTapHint;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return AppEmptyStateDropZone(
      icon: CupertinoIcons.photo_on_rectangle,
      title: emptyTitle,
      subtitle: emptyMaxPhotosLine,
      hint: emptyTapHint,
      onTap: onTap,
      semanticsLabel: semanticsLabel,
    );
  }
}
