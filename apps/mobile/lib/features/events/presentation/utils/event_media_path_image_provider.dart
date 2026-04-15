import 'dart:io';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';

/// [EcoEvent.afterImagePaths] may be local files, `assets/…`, or signed HTTPS URLs from the API.
ImageProvider eventMediaPathToImageProvider(String path) {
  final String t = path.trim();
  if (t.startsWith('assets/')) {
    return AssetImage(t);
  }
  if (EcoEventCoverImage.isNetworkUrl(t)) {
    return NetworkImage(t);
  }
  return FileImage(File(t));
}
