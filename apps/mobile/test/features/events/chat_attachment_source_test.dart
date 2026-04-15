import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isEventChatRemoteAttachmentUrl', () {
    test('true for http and https', () {
      expect(isEventChatRemoteAttachmentUrl('https://cdn.example.com/a.jpg'), isTrue);
      expect(isEventChatRemoteAttachmentUrl('http://x/y'), isTrue);
    });

    test('false for paths and file scheme', () {
      expect(isEventChatRemoteAttachmentUrl('/tmp/a.jpg'), isFalse);
      expect(isEventChatRemoteAttachmentUrl('file:///tmp/a.jpg'), isFalse);
      expect(isEventChatRemoteAttachmentUrl('C:\\\\temp\\\\a.jpg'), isFalse);
    });
  });

  group('eventChatAttachmentFilePath', () {
    test('strips file scheme', () {
      expect(eventChatAttachmentFilePath('file:///tmp/chat_attachment_source_foo.jpg'),
          '/tmp/chat_attachment_source_foo.jpg');
    });

    test('returns bare path unchanged', () {
      expect(eventChatAttachmentFilePath('/data/user/0/app/cache/x.png'), '/data/user/0/app/cache/x.png');
    });
  });
}
