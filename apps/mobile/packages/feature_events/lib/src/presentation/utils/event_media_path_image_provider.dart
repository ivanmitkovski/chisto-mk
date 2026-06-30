import 'dart:io';

import 'package:chisto_infrastructure/core/cache/site_image_provider.dart';
import 'package:feature_events/src/presentation/widgets/event_cover_image.dart';
import 'package:flutter/material.dart';

/// [EcoEvent.afterImagePaths] may be local files, `assets/…`, or signed HTTPS URLs from the API.
ImageProvider eventMediaPathToImageProvider(String path) {
  final String t = path.trim();
  if (t.startsWith('assets/')) {
    return AssetImage(t);
  }
  if (EcoEventCoverImage.isNetworkUrl(t)) {
    return imageProviderForEventCover(t);
  }
  return FileImage(File(t));
}
