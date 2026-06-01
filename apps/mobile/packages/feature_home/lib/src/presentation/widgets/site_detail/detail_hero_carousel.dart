import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/site_image_resolver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetailHeroCarousel extends StatelessWidget {
  const DetailHeroCarousel({super.key, required this.site});

  final PollutionSite site;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<ImageProvider> gallery = siteGalleryImageProviders(site);
    final List<GalleryImageItem> items = List<GalleryImageItem>.generate(
      gallery.length,
      (int index) => GalleryImageItem(
        image: gallery[index],
        semanticLabel: context.l10n.siteDetailGalleryPhotoSemantic(index + 1),
      ),
    );

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.mediaHero(colorScheme),
      ),
      child: ImmersivePhotoGallery(
        items: items,
        borderRadius: AppSpacing.radiusCard,
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      site.statusLabel,
                      style: AppTypography.badgeLabel(
                        textTheme,
                      ).copyWith(color: AppColors.textOnDark),
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
                      style: AppTypography.chipLabel(textTheme).copyWith(
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
