import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/cache/site_image_provider.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

/// Cached, downscaled network provider for map thumbnails; falls back to [PollutionSite.imageProvider].
ImageProvider mapPinImageProviderForSite(PollutionSite site) {
  final String? url = site.primaryImageUrl;
  if (url != null &&
      (url.startsWith('http://') || url.startsWith('https://'))) {
    return imageProviderForMapPin(url);
  }
  return site.imageProvider;
}
