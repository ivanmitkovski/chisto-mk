import 'package:chisto_infrastructure/core/cache/report_image_provider.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/file_exists.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/presentation/theme/report_tokens.dart';
import 'package:flutter/material.dart';

/// Evidence carousel / gallery for the report detail sheet.
class ReportDetailEvidenceGallery extends StatefulWidget {
  const ReportDetailEvidenceGallery({
    super.key,
    required this.evidencePaths,
    required this.reportTag,
    required this.noPhotosLabel,
    this.onImageError,
  });

  final List<String> evidencePaths;
  final String reportTag;
  final String noPhotosLabel;

  /// Invoked when an evidence image fails to load (e.g. expired presigned URL).
  final VoidCallback? onImageError;

  @override
  State<ReportDetailEvidenceGallery> createState() =>
      _ReportDetailEvidenceGalleryState();
}

class _ReportDetailEvidenceGalleryState
    extends State<ReportDetailEvidenceGallery> {
  List<GalleryImageItem>? _items;
  String? _itemsCacheKey;

  static bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static List<String> _validPaths(List<String> paths) {
    return paths
        .where((String path) {
          if (_isNetworkUrl(path)) return true;
          return fileExistsSync(path);
        })
        .toList(growable: false);
  }

  void _rebuildItemsIfNeeded(BuildContext context) {
    final List<String> validPaths = _validPaths(widget.evidencePaths);
    final int maxW = reportEvidenceDecodeWidthCap(context);
    final String cacheKey = '$maxW\u0001${validPaths.join('\u0001')}';
    if (_itemsCacheKey == cacheKey && _items != null) {
      return;
    }
    _itemsCacheKey = cacheKey;
    if (validPaths.isEmpty) {
      _items = <GalleryImageItem>[];
      return;
    }

    final AppLocalizations l10n = context.l10n;
    _items = List<GalleryImageItem>.generate(validPaths.length, (int index) {
      final String path = validPaths[index];
      return GalleryImageItem(
        image: imageProviderForReportEvidence(path, maxWidth: maxW),
        heroTag: 'report-evidence-${widget.reportTag}-$index',
        semanticLabel: l10n.reportDetailEvidencePhotoSemantic(index + 1),
      );
    }, growable: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildItemsIfNeeded(context);
  }

  @override
  void didUpdateWidget(covariant ReportDetailEvidenceGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evidencePaths != widget.evidencePaths ||
        oldWidget.reportTag != widget.reportTag) {
      _items = null;
      _itemsCacheKey = null;
    }
    _rebuildItemsIfNeeded(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<GalleryImageItem> items = _items ?? <GalleryImageItem>[];

    if (items.isEmpty) {
      return AspectRatio(
        aspectRatio: ReportTokens.evidenceAspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radius22),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.image_not_supported_outlined,
                  size: 32,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.noPhotosLabel,
                  style: AppTypography.textTheme.bodySmall!.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final AppLocalizations l10n = context.l10n;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius22),
      child: ImmersivePhotoGallery(
        items: items,
        aspectRatio: ReportTokens.evidenceAspectRatio,
        borderRadius: 0,
        onImageError: widget.onImageError,
        openLabel: l10n.reportDetailEvidenceGalleryOpenSemantic,
        bottomCenterBuilder:
            (BuildContext sheetContext, int currentIndex, int totalCount) {
              return GalleryGlassPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.photo_library_outlined,
                      size: ReportTokens.galleryGlassIconSize,
                      color: AppColors.textOnDark,
                    ),
                    const SizedBox(width: ReportTokens.galleryGlassIconTextGap),
                    Text(
                      totalCount > 1
                          ? l10n.reportDetailEvidenceTapToExpand
                          : l10n.reportDetailEvidenceOpenPhoto,
                      style: AppTypographySurfaces.reportsGalleryHint(
                        Theme.of(sheetContext).textTheme,
                      ),
                    ),
                  ],
                ),
              );
            },
      ),
    );
  }
}
