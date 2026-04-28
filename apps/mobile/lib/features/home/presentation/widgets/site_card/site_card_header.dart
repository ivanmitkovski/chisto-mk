import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';

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
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusLine,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
