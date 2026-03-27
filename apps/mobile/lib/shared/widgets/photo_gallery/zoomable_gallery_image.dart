import 'package:flutter/material.dart';

import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:chisto_mobile/shared/widgets/photo_gallery/gallery_image_item.dart';

typedef GalleryInteractionEndCallback =
    void Function(ScaleEndDetails details, Size viewportSize);

class ZoomableGalleryImage extends StatefulWidget {
  const ZoomableGalleryImage({
    super.key,
    required this.item,
    required this.controller,
    required this.onDoubleTap,
    this.onInteractionEnd,
  });

  final GalleryImageItem item;
  final TransformationController controller;
  final ValueChanged<TapDownDetails> onDoubleTap;
  final GalleryInteractionEndCallback? onInteractionEnd;

  @override
  State<ZoomableGalleryImage> createState() => _ZoomableGalleryImageState();
}

class _ZoomableGalleryImageState extends State<ZoomableGalleryImage> {
  TapDownDetails? _doubleTapDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (TapDownDetails details) {
        _doubleTapDetails = details;
      },
      onDoubleTap: () {
        final TapDownDetails? details = _doubleTapDetails;
        if (details == null) return;
        widget.onDoubleTap(details);
      },
      child: InteractiveViewer(
        transformationController: widget.controller,
        minScale: 1,
        maxScale: 4.5,
        panEnabled: true,
        scaleEnabled: true,
        onInteractionEnd: (ScaleEndDetails details) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          final Size viewport = box?.size ?? Size.zero;
          widget.onInteractionEnd?.call(details, viewport);
        },
        clipBehavior: Clip.none,
        // Keep pan bounds tight so images do not drift into corner-stuck states.
        boundaryMargin: EdgeInsets.zero,
        child: Center(
          child: AppSmartImage(
            image: widget.item.image,
            fit: BoxFit.contain,
            semanticLabel: widget.item.semanticLabel,
            decodePreset: AppSmartImageDecodePreset.fullQuality,
            enableRetry: false,
          ),
        ),
      ),
    );
  }
}
