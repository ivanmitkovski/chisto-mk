import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_image_hero_tag.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_card_header.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_card_menu.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';

/// 16:9 gallery strip for a feed site card (page dots, status pill, overflow menu).
class SiteCardImageCarousel extends StatefulWidget {
  const SiteCardImageCarousel({
    super.key,
    required this.siteId,
    required this.siteTitle,
    required this.images,
    required this.statusColor,
    required this.statusLine,
    required this.onMenuTap,
    required this.onPageIndexChanged,
  });

  final String siteId;
  final String siteTitle;
  final List<ImageProvider> images;
  final Color statusColor;
  final String statusLine;
  final VoidCallback onMenuTap;
  final ValueChanged<int> onPageIndexChanged;

  @override
  State<SiteCardImageCarousel> createState() => _SiteCardImageCarouselState();
}

class _SiteCardImageCarouselState extends State<SiteCardImageCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ImageProvider> images = widget.images;

    return Semantics(
      image: true,
      label: context.l10n.siteCardPhotoSemantic(widget.siteTitle),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (int index) {
                AppHaptics.light();
                setState(() => _currentIndex = index);
                widget.onPageIndexChanged(index);
              },
              physics: const BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                final Widget image = AppSmartImage(
                  image: images[index],
                  semanticLabel: context.l10n.siteCardGalleryPhotoSemantic(
                    index + 1,
                    widget.siteTitle,
                  ),
                  decodePreset: AppSmartImageDecodePreset.feed,
                );
                return SizedBox.expand(
                  child: Hero(
                    tag: siteImageHeroTag(widget.siteId, index),
                    child: image,
                  ),
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.black.withValues(alpha: 0.28),
                        AppColors.transparent,
                        AppColors.black.withValues(alpha: 0.2),
                      ],
                      stops: const <double>[0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
            SiteCardFeedStatusPill(
              statusColor: widget.statusColor,
              statusLine: widget.statusLine,
            ),
            SiteCardOverflowMenuButton(onMenuTap: widget.onMenuTap),
            if (images.length > 1)
              Positioned(
                bottom: AppSpacing.sm,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 52,
                    child: Center(
                      child: GalleryPageIndicators(
                        currentIndex: _currentIndex,
                        totalCount: images.length,
                        maxVisible: 4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
