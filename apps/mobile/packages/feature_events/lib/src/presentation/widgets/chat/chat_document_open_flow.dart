import 'dart:io';
import 'dart:typed_data';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_pdf_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Opens a chat file attachment: PDF in-app; other types saved and opened / shared.
Future<void> openChatDocument(
  BuildContext context,
  EventChatAttachment attachment, {
  required Future<Uint8List> Function(String url) downloadRemote,
}) async {
  final String mime = attachment.mimeType.toLowerCase();

  try {
    late final Uint8List bodyBytes;
    if (!isEventChatRemoteAttachmentUrl(attachment.url)) {
      bodyBytes = await File(
        eventChatAttachmentFilePath(attachment.url),
      ).readAsBytes();
    } else {
      try {
        bodyBytes = await downloadRemote(attachment.url);
      } on Object {
        if (context.mounted) {
          AppSnack.show(context, message: context.l10n.eventChatDownloadFailed);
        }
        return;
      }
    }
    if (!context.mounted) {
      return;
    }
    if (mime.contains('pdf')) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext ctx) => ChatPdfViewerScreen(
            bytes: bodyBytes,
            title: attachment.fileName.isNotEmpty ? attachment.fileName : 'PDF',
          ),
        ),
      );
      return;
    }
    final Directory dir = await getTemporaryDirectory();
    final String safeName = attachment.fileName.replaceAll(
      RegExp(r'[/\\]'),
      '_',
    );
    final String path = '${dir.path}/chat_${attachment.id}_$safeName';
    final File out = File(path);
    await out.writeAsBytes(bodyBytes, flush: true);
    if (!context.mounted) {
      return;
    }
    final OpenResult result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      await Share.shareXFiles(<XFile>[XFile(path)], text: attachment.fileName);
    }
  } on Object {
    if (context.mounted) {
      AppSnack.show(context, message: context.l10n.eventChatDownloadFailed);
    }
  }
}
