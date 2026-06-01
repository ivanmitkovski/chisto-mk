import 'dart:typed_data';

import 'package:feature_events/src/domain/repositories/event_chat_attachment_port.dart';
import 'package:http/http.dart' as http;

/// Downloads signed chat attachment URLs over plain HTTP.
class HttpEventChatAttachmentDownloader implements EventChatAttachmentPort {
  HttpEventChatAttachmentDownloader({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Uint8List> downloadRemoteAttachment(String url) async {
    final http.Response resp = await _client.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw StateError('HTTP ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }
}
