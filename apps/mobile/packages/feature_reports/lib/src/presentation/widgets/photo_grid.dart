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
  });

  final List<XFile> photos;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhoto;

  /// Stable id for [Hero] tags (`report-photo-{reportId}-{index}`).
  final String reportId;
  final int maxPhotos;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!hasPhotos)
          _EmptyPhotoGalleryCard(onTap: widget.onAddPhoto)
        else ...<Widget>[
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
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length + (canAdd ? 1 : 0),
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                if (index == widget.photos.length && canAdd) {
                  return _AddPhotoTile.compact(onTap: widget.onAddPhoto);
                }
                return _PhotoThumbnail(
                  file: widget.photos[index],
                  index: index,
                  totalCount: widget.photos.length,
                  isSelected: index == _selectedIndex,
                  onSelect: () {
                    setState(() => _selectedIndex = index);
                  },
                  onRemove: () => widget.onRemovePhoto(index),
                );
              },
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
          boxShadow: AppShadows.card(Theme.of(context).colorScheme),
        ),
        child: _AddPhotoTile.expanded(onTap: onTap),
      ),
    );
  }
}
