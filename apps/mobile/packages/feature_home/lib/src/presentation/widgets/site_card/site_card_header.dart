import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Status glance line overlaid on the feed card image (site lifecycle + label).
class SiteCardFeedStatusPill extends StatelessWidget {
  const SiteCardFeedStatusPill({
    super.key,
    required this.statusColor,
    required this.statusLine,
  });

  final Color statusColor;
  final String statusLine;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.sm,
      child: GalleryGlassPill(
        emphasis: GalleryGlassPillEmphasis.strong,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: AppRadii.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusLine,
              style: AppTypography.badgeLabel(
                textTheme,
              ).copyWith(color: AppColors.textOnDark),
            ),
          ],
        ),
      ),
    );
  }
}
