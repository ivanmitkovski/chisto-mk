import 'package:flutter/material.dart';

class GalleryImageItem {
  const GalleryImageItem({
    required this.image,
    required this.heroTag,
    this.semanticLabel,
  });

  final ImageProvider image;
  final String heroTag;
  final String? semanticLabel;
}
