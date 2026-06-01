import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:feature_events/src/presentation/utils/event_media_path_image_provider.dart';
import 'package:flutter/material.dart';

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
            image: eventMediaPathToImageProvider(path),
            heroTag: 'cleanup-evidence-$path',
            semanticLabel: context.l10n.eventsCleanupEvidencePhotoSemantic,
          ),
        )
        .toList();
    return FullscreenPhotoGalleryScreen(
      items: items,
      initialIndex: initialIndex.clamp(0, items.length - 1),
    );
  }
}
