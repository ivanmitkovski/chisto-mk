import 'dart:io';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_smart_image.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/report_field_limits.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoGrid extends StatefulWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    this.reportId = 'draft',
    this.maxPhotos = ReportFieldLimits.maxPhotos,
    this.compact = false,
    this.showExpandedAddCard = false,
    this.hideExpandedAddCard = false,
  });

  final List<XFile> photos;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhoto;

  /// Stable id for [Hero] tags (`report-photo-{reportId}-{index}`).
  final String reportId;
  final int maxPhotos;

  /// When true and [photos] are non-empty, shows only the count + thumbnail strip
  /// (keyboard-friendly). Empty state always uses the large add-photo card.
  final bool compact;

  /// When true and more photos can be added, keeps the large add-photo card
  /// ("Camera or library") above the thumbnail strip instead of a compact Add tile.
  final bool showExpandedAddCard;

  /// When true, hides the large add-photo card with animation (resolution sheet
  /// keyboard mode). Only applies when [showExpandedAddCard] is true and photos exist.
  final bool hideExpandedAddCard;

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant PhotoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.isEmpty) {
      _selectedIndex = 0;
      return;
    }
    if (_selectedIndex >= widget.photos.length) {
      _selectedIndex = widget.photos.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool hasPhotos = widget.photos.isNotEmpty;
    final bool canAdd = widget.photos.length < widget.maxPhotos;
    final List<GalleryImageItem> galleryItems = List<GalleryImageItem>.generate(
      widget.photos.length,
      (int index) => GalleryImageItem(
        image: FileImage(File(widget.photos[index].path), scale: 1),
        heroTag: 'report-photo-${widget.reportId}-$index',
        semanticLabel: l10n.reportPhotoSemanticReportPhoto(index + 1),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
          if (!hasPhotos)
            _EmptyPhotoGalleryCard(onTap: widget.onAddPhoto)
          else if (widget.compact) ...<Widget>[
            Text(
              l10n.reportPhotoGridAttachedCount(
                widget.photos.length,
                widget.maxPhotos,
              ),
              style: AppTypographySurfaces.reportsPhotoGridCount(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.showExpandedAddCard && canAdd)
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.smooth,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: widget.hideExpandedAddCard
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _EmptyPhotoGalleryCard(onTap: widget.onAddPhoto),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
              ),
            _buildThumbnailStrip(
              canAdd: canAdd && !widget.showExpandedAddCard,
            ),
          ] else ...<Widget>[
            Text(
              l10n.reportPhotoGridAttachedCount(
                widget.photos.length,
                widget.maxPhotos,
              ),
              style: AppTypographySurfaces.reportsPhotoGridCount(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ImmersivePhotoGallery(
              items: galleryItems,
              selectedIndex: _selectedIndex,
              onPageChanged: (int index) {
                if (!mounted) return;
                setState(() => _selectedIndex = index);
              },
              openLabel: l10n.reportPhotoOpenGallerySemantic,
              bottomCenterBuilder:
                  (BuildContext context, int currentIndex, int totalCount) {
                    return GalleryGlassPill(
                      child: Text(
                        totalCount > 1
                            ? l10n.reportPhotoTapToReviewMany
                            : l10n.reportPhotoTapToReviewSingle,
                        style: AppTypographySurfaces.reportsPhotoGalleryPill(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    );
                  },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.photos.length == 1
                  ? l10n.reportPhotoStackCaptionSingle
                  : l10n.reportPhotoStackCaptionMany(widget.photos.length),
              style: AppTypographySurfaces.reportsPhotoGridHint(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildThumbnailStrip(canAdd: canAdd),
          ],
          if (!widget.compact) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasPhotos
                  ? (_selectedIndex == 0
                        ? l10n.reportPhotoVerificationHelpPrimarySelected
                        : l10n.reportPhotoVerificationHelpPrimaryOther)
                  : l10n.reportPhotoVerificationHelpEmpty,
              style: AppTypographySurfaces.reportsPhotoGridHint(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ],
    );
  }

  static const double _thumbTileWidth = 72;
  static const double _stripHeight = 86;

  double _stripContentWidth({required int photoCount, required bool canAdd}) {
    if (photoCount == 0) {
      return canAdd ? _thumbTileWidth : 0;
    }
    double width =
        photoCount * _thumbTileWidth + (photoCount - 1) * AppSpacing.sm;
    if (canAdd) {
      width += AppSpacing.sm + _thumbTileWidth;
    }
    return width;
  }

  Widget _buildThumbnailStrip({required bool canAdd}) {
    final List<Widget> children = <Widget>[];
    for (int index = 0; index < widget.photos.length; index++) {
      if (index > 0) {
        children.add(const SizedBox(width: AppSpacing.sm));
      }
      children.add(
        _PhotoThumbnail(
          file: widget.photos[index],
          index: index,
          totalCount: widget.photos.length,
          isSelected: index == _selectedIndex,
          onSelect: () {
            setState(() => _selectedIndex = index);
          },
          onRemove: () => widget.onRemovePhoto(index),
        ),
      );
    }
    if (canAdd) {
      if (widget.photos.isNotEmpty) {
        children.add(const SizedBox(width: AppSpacing.sm));
      }
      children.add(
        KeyedSubtree(
          key: const ValueKey<String>('photo-grid-add-tile'),
          child: _AddPhotoTile.compact(onTap: widget.onAddPhoto),
        ),
      );
    }

    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    final double contentWidth = _stripContentWidth(
      photoCount: widget.photos.length,
      canAdd: canAdd,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool needsHorizontalScroll =
              contentWidth > constraints.maxWidth;
          return SizedBox(
            height: _stripHeight,
            width: constraints.maxWidth,
            child: needsHorizontalScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    physics: const ClampingScrollPhysics(),
                    child: row,
                  )
                : Align(alignment: Alignment.centerLeft, child: row),
          );
        },
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.file,
    required this.index,
    required this.totalCount,
    required this.isSelected,
    required this.onSelect,
    required this.onRemove,
  });

  final XFile file;
  final int index;
  final int totalCount;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      button: true,
      label: totalCount > 0
          ? l10n.reportPhotoSemanticThumbnail(index + 1, totalCount)
          : l10n.reportPhotoSemanticThumbnail(index + 1, 1),
      child: GestureDetector(
        onTap: onSelect,
        child: SizedBox(
          width: 72,
          height: 86,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  padding: const EdgeInsets.all(AppSpacing.radiusHandle),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radius18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.divider,
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? AppShadows.photoGridSelected()
                        : const <BoxShadow>[],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radius14),
                    child: AppSmartImage(
                      image: FileImage(File(file.path), scale: 1),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Semantics(
                  button: true,
                  label: l10n.reportPhotoSemanticRemove,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile.expanded({required this.onTap}) : _isCompact = false;

  const _AddPhotoTile.compact({required this.onTap}) : _isCompact = true;

  final VoidCallback onTap;
  final bool _isCompact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.reportPhotoSemanticAddPhoto,
      child: GestureDetector(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Container(
          width: _isCompact ? 72 : double.infinity,
          height: _isCompact ? 86 : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              _isCompact ? AppSpacing.radius18 : AppSpacing.radiusXl,
            ),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.9),
              width: 1.2,
            ),
            color: AppColors.inputFill,
            boxShadow: _isCompact ? AppShadows.photoGridCompactAddTile() : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: _isCompact ? 32 : 42,
                  height: _isCompact ? 32 : 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      _isCompact ? AppSpacing.radius10 : AppSpacing.radiusMd,
                    ),
                  ),
                  child: Icon(
                    _isCompact ? Icons.add_rounded : Icons.camera_alt_rounded,
                    size: _isCompact ? 16 : 20,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isCompact
                      ? context.l10n.reportPhotoGridAddShort
                      : context.l10n.reportPhotoGridAdd,
                  style: AppTypographySurfaces.reportsPillLabel(
                    Theme.of(context).textTheme,
                  ).copyWith(color: AppColors.primaryDark),
                ),
                if (!_isCompact) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.l10n.reportPhotoGridSourceHint,
                    style: AppTypographySurfaces.reportsBadgeLabel(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPhotoGalleryCard extends StatelessWidget {
  const _EmptyPhotoGalleryCard({required this.onTap});

  final VoidCallback onTap;

  static const EdgeInsets _shadowBleed = EdgeInsets.fromLTRB(0, 2, 0, 10);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _shadowBleed,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
            boxShadow: AppShadows.photoGridEmptyCard(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            child: _AddPhotoTile.expanded(onTap: onTap),
          ),
        ),
      ),
    );
  }
}
