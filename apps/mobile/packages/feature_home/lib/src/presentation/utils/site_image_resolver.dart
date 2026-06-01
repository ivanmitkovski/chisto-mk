import 'package:chisto_infrastructure/core/cache/site_image_provider.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/site_report.dart';
import 'package:flutter/material.dart';

const AssetImage kSiteImagePlaceholder = AssetImage(
  'assets/images/content/people_cleaning.png',
);

ImageProvider sitePrimaryImageProvider(PollutionSite site) {
  final String? u = site.primaryImageUrl?.trim();
  if (u == null || u.isEmpty) {
    return kSiteImagePlaceholder;
  }
  return imageProviderForSiteMedia(u);
}

List<ImageProvider> siteGalleryImageProviders(PollutionSite site) {
  if (site.mediaUrls.isEmpty) {
    return <ImageProvider>[kSiteImagePlaceholder];
  }
  return site.mediaUrls
      .map((String u) => u.trim())
      .where((String u) => u.isNotEmpty)
      .map(imageProviderForSiteMedia)
      .toList();
}

List<ImageProvider> siteReportGalleryImageProviders(SiteReport report) {
  if (report.imageUrls.isEmpty) {
    return <ImageProvider>[kSiteImagePlaceholder];
  }
  return report.imageUrls
      .map((String u) => u.trim())
      .where((String u) => u.isNotEmpty)
      .map(imageProviderForSiteMedia)
      .toList();
}

/// HTTP(S) URLs suitable for [SiteImagePrefetchQueue] / cache warm-up.
List<String> siteGalleryPrefetchUrls(PollutionSite site) {
  if (site.mediaUrls.isEmpty) {
    return const <String>[];
  }
  return site.mediaUrls
      .map((String u) => u.trim())
      .where(
        (String u) =>
            u.isNotEmpty &&
            (u.startsWith('http://') || u.startsWith('https://')),
      )
      .toList();
}
