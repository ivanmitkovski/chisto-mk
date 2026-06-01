import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:flutter/material.dart';

/// Fills a tile with a remote or local chat image attachment.
Widget eventChatImageTile(
  EventChatAttachment attachment, {
  required int cacheWidth,
}) {
  if (isEventChatRemoteAttachmentUrl(attachment.url)) {
    return CachedNetworkImage(
      imageUrl: attachment.url,
      cacheKey: eventChatAttachmentCacheKey(attachment),
      fit: BoxFit.cover,
      memCacheWidth: cacheWidth,
      errorWidget: (BuildContext context, String url, Object error) =>
          const ColoredBox(
            color: AppColors.inputFill,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.textMuted,
              ),
            ),
          ),
    );
  }
  return Image.file(
    File(eventChatAttachmentFilePath(attachment.url)),
    fit: BoxFit.cover,
    cacheWidth: cacheWidth,
    errorBuilder:
        (BuildContext context, Object error, StackTrace? stackTrace) =>
            const ColoredBox(
              color: AppColors.inputFill,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
  );
}
