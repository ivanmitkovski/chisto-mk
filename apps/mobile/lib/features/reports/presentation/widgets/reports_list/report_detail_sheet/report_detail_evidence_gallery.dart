import 'package:chisto_mobile/core/cache/report_image_provider.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/theme/report_tokens.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/file_exists.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';
import 'package:flutter/material.dart';

/// Evidence carousel / gallery for the report detail sheet.
class ReportDetailEvidenceGallery extends StatelessWidget {
  const ReportDetailEvidenceGallery({
    super.key,
    required this.evidencePaths,
    required this.reportTag,
    required this.noPhotosLabel,
  });

  final List<String> evidencePaths;
  final String reportTag;
  final String noPhotosLabel;

  static bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static List<String> _validPaths(List<String> paths) {
    return paths.where((String path) {
      if (_isNetworkUrl(path)) return true;
      return fileExistsSync(path);
    }).toList();
  }

  static int _decodeWidthCap(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double px = mq.size.width * mq.devicePixelRatio;
    return px.clamp(1, 1280).round();
  }

  static ImageProvider _imageForPath(BuildContext context, String path) {
    final int maxW = _decodeWidthCap(context);
    return imageProviderForReportEvidence(path, maxWidth: maxW);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> validPaths = _validPaths(evidencePaths);
    if (validPaths.isEmpty) {
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
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 32,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  noPhotosLabel,
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
    final List<GalleryImageItem> items = List<GalleryImageItem>.generate(
      validPaths.length,
      (int index) => GalleryImageItem(
        image: _imageForPath(context, validPaths[index]),
        heroTag: 'report-evidence-$reportTag-$index',
        semanticLabel: l10n.reportDetailEvidencePhotoSemantic(index + 1),
      ),
    );

    final Widget gallery = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius22),
      child: ImmersivePhotoGallery(
        items: items,
        aspectRatio: ReportTokens.evidenceAspectRatio,
        borderRadius: 0,
        openLabel: l10n.reportDetailEvidenceGalleryOpenSemantic,
        bottomCenterBuilder:
            (BuildContext sheetContext, int currentIndex, int totalCount) {
              return GalleryGlassPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.photo_library_outlined,
                      size: ReportTokens.galleryGlassIconSize,
                      color: AppColors.textOnDark,
                    ),
                    SizedBox(width: ReportTokens.galleryGlassIconTextGap),
                    Text(
                      totalCount > 1
                          ? l10n.reportDetailEvidenceTapToExpand
                          : l10n.reportDetailEvidenceOpenPhoto,
                      style: AppTypography.reportsGalleryHint(
                        Theme.of(sheetContext).textTheme,
                      ),
                    ),
                  ],
                ),
              );
            },
      ),
    );
    if (validPaths.length == 1) {
      return Hero(tag: 'report-evidence-hero-$reportTag', child: gallery);
    }
    return gallery;
  }
}
