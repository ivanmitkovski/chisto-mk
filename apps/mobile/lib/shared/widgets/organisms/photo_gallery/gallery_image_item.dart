import 'package:flutter/material.dart';

class GalleryImageItem {
  const GalleryImageItem({
    required this.image,
    this.heroTag,
    this.semanticLabel,
  });

  final ImageProvider image;
  /// When null, gallery tiles render without a [Hero] flight.
  final String? heroTag;
  final String? semanticLabel;
}
