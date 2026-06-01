import 'dart:typed_data';

/// Downloads remote chat attachment bytes (signed URLs, etc.).
// ignore: one_member_abstracts, intentional injectable port
abstract class EventChatAttachmentPort {
  Future<Uint8List> downloadRemoteAttachment(String url);
}
