import 'dart:io';
import 'dart:typed_data';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_pdf_viewer_screen.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Opens a chat file attachment: PDF in-app; other types saved and opened / shared.
Future<void> openChatDocument(BuildContext context, EventChatAttachment attachment) async {
  final String mime = attachment.mimeType.toLowerCase();

  try {
    late final Uint8List bodyBytes;
    if (!isEventChatRemoteAttachmentUrl(attachment.url)) {
      bodyBytes = await File(eventChatAttachmentFilePath(attachment.url)).readAsBytes();
    } else {
      final http.Response resp = await http.get(Uri.parse(attachment.url));
      if (resp.statusCode != 200) {
        if (context.mounted) {
          AppSnack.show(context, message: context.l10n.eventChatDownloadFailed);
        }
        return;
      }
      bodyBytes = resp.bodyBytes;
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
    final String safeName = attachment.fileName.replaceAll(RegExp(r'[/\\]'), '_');
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
