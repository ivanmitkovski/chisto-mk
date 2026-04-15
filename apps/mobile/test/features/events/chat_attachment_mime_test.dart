import 'dart:typed_data';

import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_mime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatAttachmentMime.infer', () {
    test('maps extensions when bytes are empty', () {
      final Uint8List empty = Uint8List(0);
      expect(ChatAttachmentMime.infer('photo.png', empty), 'image/png');
      expect(ChatAttachmentMime.infer('clip.m4a', empty), 'audio/m4a');
      expect(ChatAttachmentMime.infer('doc.pdf', empty), 'application/pdf');
      expect(ChatAttachmentMime.infer('movie.mp4', empty), 'video/mp4');
      expect(ChatAttachmentMime.infer('note.txt', empty), 'text/plain');
    });

    test('uses JPEG magic bytes when extension is wrong', () {
      final Uint8List jpeg = Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0xe0, 0, 0]);
      expect(ChatAttachmentMime.infer('wrong.bin', jpeg), 'image/jpeg');
    });
  });
}
