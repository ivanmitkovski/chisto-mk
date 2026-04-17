import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

import 'dashed_border_painter.dart';

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
        child: Semantics(
          button: true,
          label: context.l10n.eventsCleanupAfterUploadSemantic,
          child: AddPhotosEmptyState(
            maxImages: maxImages,
            onTap: onPick,
            textTheme: textTheme,
            emptyTitle: context.l10n.eventsCleanupAfterEmptyTitle,
            emptyMaxPhotosLine: context.l10n.eventsCleanupAfterEmptyMaxPhotos(maxImages),
            emptyTapHint: context.l10n.eventsCleanupAfterEmptyTapGallery,
          ),
        ),
      );
    }

    final String selectedPath = afterImages[selectedIndex.clamp(0, afterImages.length - 1)];
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
                  onTap: () => onImageTap(selectedIndex.clamp(0, afterImages.length - 1)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: buildImage(
                      selectedPath,
                      height: heroHeight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(AppSpacing.sheetHandle, AppSpacing.sheetHandle),
                  onPressed: () => onRemove(
                    selectedIndex.clamp(0, afterImages.length - 1),
                  ),
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
                      color: AppColors.accentDanger,
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
                context.l10n.eventsCleanupAfterUploadedCount(afterImages.length),
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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radius10),
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
                          label: context.l10n.eventsCleanupAfterRemoveSemantic,
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
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.black
                                        .withValues(alpha: 0.12),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.minus_circle_fill,
                                size: 20,
                                color: AppColors.accentDanger,
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

class AddPhotosEmptyState extends StatefulWidget {
  const AddPhotosEmptyState({
    super.key,
    required this.maxImages,
    required this.onTap,
    required this.textTheme,
    required this.emptyTitle,
    required this.emptyMaxPhotosLine,
    required this.emptyTapHint,
  });

  final int maxImages;
  final VoidCallback onTap;
  final TextTheme textTheme;
  final String emptyTitle;
  final String emptyMaxPhotosLine;
  final String emptyTapHint;

  @override
  State<AddPhotosEmptyState> createState() => _AddPhotosEmptyStateState();
}

class _AddPhotosEmptyStateState extends State<AddPhotosEmptyState>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (MediaQuery.disableAnimationsOf(context)) {
        _pulseController.value = 1.0;
      } else {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: FadeTransition(
        opacity: _pulseAnimation,
        child: AnimatedContainer(
        duration: AppMotion.xFast,
        curve: AppMotion.emphasized,
        transform: Matrix4.diagonal3Values(
          _pressed ? 0.98 : 1.0,
          _pressed ? 0.98 : 1.0,
          1.0,
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: AppColors.primary.withValues(alpha: 0.45),
            borderRadius: AppSpacing.radiusXl,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 32,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.emptyTitle,
                    style: AppTypography.eventsSheetTitle(widget.textTheme),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.emptyMaxPhotosLine,
                    style: AppTypography.eventsSupportingCaption(widget.textTheme)
                        .copyWith(height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: AppColors.primaryDark.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.emptyTapHint,
                        style: AppTypography.eventsSheetTextLink(widget.textTheme)
                            .copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ),
      ),
      ),
    );
  }
}
