import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/cache/site_image_provider.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_image_resolver.dart';

/// Cached, downscaled network provider for map thumbnails; falls back to placeholder.
ImageProvider mapPinImageProviderForSite(PollutionSite site) {
  final String? url = site.primaryImageUrl;
  if (url != null &&
      (url.startsWith('http://') || url.startsWith('https://'))) {
    return imageProviderForMapPin(url);
  }
  return sitePrimaryImageProvider(site);
}

/// Pin thumbnail that fades from a tonal placeholder circle into loaded pixels.
class MapPinThumbnail extends StatelessWidget {
  const MapPinThumbnail({super.key, required this.site});

  final PollutionSite site;

  @override
  Widget build(BuildContext context) {
    final bool disableMotion =
        MediaQuery.disableAnimationsOf(context);

    return Image(
      image: mapPinImageProviderForSite(site),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        final bool visible = frame != null || wasSynchronouslyLoaded;
        final Duration fadeDuration =
            disableMotion ? Duration.zero : AppMotion.medium;
        final Color halo = AppColors.white;
        final Color haloEdge = site.statusColor.withValues(alpha: 0.35);

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    halo,
                    haloEdge,
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: fadeDuration,
              curve: AppMotion.smooth,
              child: child,
            ),
          ],
        );
      },
    );
  }
}
