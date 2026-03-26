import 'dart:io';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';

class CleanupFullscreenGalleryPage extends StatelessWidget {
  const CleanupFullscreenGalleryPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  final List<String> imagePaths;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final List<GalleryImageItem> items = imagePaths
        .map(
          (String path) => GalleryImageItem(
            image: path.startsWith('assets/')
                ? AssetImage(path)
                : FileImage(File(path)) as ImageProvider,
            heroTag: 'cleanup-evidence-$path',
            semanticLabel: 'Cleanup evidence photo',
          ),
        )
        .toList();
    return FullscreenPhotoGalleryScreen(
      items: items,
      initialIndex: initialIndex.clamp(0, items.length - 1),
    );
  }
}
