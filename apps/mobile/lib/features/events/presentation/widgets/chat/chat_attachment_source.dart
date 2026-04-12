import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';

/// Stable cache identity when signed URLs rotate; prefer attachment id when present.
String eventChatAttachmentCacheKey(EventChatAttachment a) {
  final String id = a.id.trim();
  if (id.isNotEmpty) {
    return 'ec_att_$id';
  }
  return 'ec_url_${a.url.hashCode}';
}

/// Whether [url] is loaded over the network (vs a device file path for optimistic rows).
bool isEventChatRemoteAttachmentUrl(String url) {
  final String s = url.trim().toLowerCase();
  return s.startsWith('https://') || s.startsWith('http://');
}

/// Filesystem path for a local attachment [url] (optimistic bubble). Do not use for remote URLs.
String eventChatAttachmentFilePath(String url) {
  final String raw = url.trim();
  if (raw.toLowerCase().startsWith('file://')) {
    return Uri.parse(raw).toFilePath();
  }
  return raw;
}
