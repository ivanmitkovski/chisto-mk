import 'package:flutter/cupertino.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_image_hero_tag.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_image_resolver.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';

class DetailHeroCarousel extends StatelessWidget {
  const DetailHeroCarousel({super.key, required this.site});

  final PollutionSite site;

  @override
  Widget build(BuildContext context) {
    final List<ImageProvider> gallery = siteGalleryImageProviders(site);
    final List<GalleryImageItem> items = List<GalleryImageItem>.generate(
      gallery.length,
      (int index) => GalleryImageItem(
        image: gallery[index],
        heroTag: siteImageHeroTag(site.id, index),
        semanticLabel: context.l10n.siteDetailGalleryPhotoSemantic(index + 1),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ImmersivePhotoGallery(
        items: items,
        borderRadius: 24,
        openLabel: context.l10n.siteDetailOpenGalleryLabel,
        topLeftBuilder:
            (BuildContext context, int currentIndex, int totalCount) {
              return GalleryGlassPill(
                emphasis: GalleryGlassPillEmphasis.strong,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: site.statusColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      site.statusLabel,
                    style: AppTypography.badgeLabel.copyWith(
                      color: AppColors.textOnDark,
                    ),
                    ),
                  ],
                ),
              );
            },
        bottomCenterBuilder:
            (BuildContext context, int currentIndex, int totalCount) {
              return GalleryGlassPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.sparkles,
                      size: 13,
                      color: AppColors.textOnDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      totalCount > 1
                          ? context.l10n.siteDetailGalleryTapToExpand
                          : context.l10n.siteDetailGalleryOpenPhoto,
                      style: AppTypography.chipLabel.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textOnDark,
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
