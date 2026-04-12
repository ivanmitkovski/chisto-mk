import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

Future<void> openChatImageGallery(
  BuildContext context, {
  required List<EventChatAttachment> attachments,
  required int initialIndex,
}) {
  if (attachments.isEmpty) {
    return Future<void>.value();
  }
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext ctx) => ChatImageGalleryScreen(
        attachments: attachments,
        initialIndex: initialIndex,
      ),
    ),
  );
}

/// Fullscreen pinch-zoom gallery for chat image attachments.
class ChatImageGalleryScreen extends StatefulWidget {
  const ChatImageGalleryScreen({
    super.key,
    required this.attachments,
    required this.initialIndex,
  });

  final List<EventChatAttachment> attachments;
  final int initialIndex;

  @override
  State<ChatImageGalleryScreen> createState() => _ChatImageGalleryScreenState();
}

class _ChatImageGalleryScreenState extends State<ChatImageGalleryScreen> {
  late int _index;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final int last = widget.attachments.length - 1;
    _index = widget.initialIndex.clamp(0, last < 0 ? 0 : last);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: context.l10n.eventChatImageViewerTitle,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            context.l10n.eventChatImageViewerPage(_index + 1, widget.attachments.length),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ),
        body: PhotoViewGallery.builder(
          scrollPhysics: reduceMotion
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            final EventChatAttachment a = widget.attachments[index];
            final ImageProvider<Object> imageProvider = isEventChatRemoteAttachmentUrl(a.url)
                ? CachedNetworkImageProvider(
                    a.url,
                    cacheKey: eventChatAttachmentCacheKey(a),
                  )
                : FileImage(File(eventChatAttachmentFilePath(a.url)));
            return PhotoViewGalleryPageOptions(
              imageProvider: imageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              filterQuality: FilterQuality.medium,
              errorBuilder: (BuildContext ctx, Object error, StackTrace? stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 56),
                );
              },
            );
          },
          itemCount: widget.attachments.length,
          loadingBuilder: (BuildContext context, ImageChunkEvent? event) {
            return Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: event == null || event.expectedTotalBytes == null
                      ? null
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  color: Colors.white54,
                ),
              ),
            );
          },
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: _pageController,
          onPageChanged: (int i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
