import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventChatAttachment.tryFromJson', () {
    test('parses upload response without id (pre-message attachment)', () {
      final EventChatAttachment? a = EventChatAttachment.tryFromJson(<String, dynamic>{
        'url': 'https://bucket.s3.eu-central-1.amazonaws.com/chat/e1/uuid.m4a',
        'mimeType': 'audio/m4a',
        'fileName': 'voice.m4a',
        'sizeBytes': 12000,
        'width': null,
        'height': null,
        'duration': null,
        'thumbnailUrl': null,
      });
      expect(a, isNotNull);
      expect(a!.id, '');
      expect(a.url, contains('chat/e1/'));
      expect(a.mimeType, 'audio/m4a');
    });

    test('still parses message attachment with id from API', () {
      final EventChatAttachment? a = EventChatAttachment.tryFromJson(<String, dynamic>{
        'id': 'att-1',
        'url': 'https://example.com/f.webp',
        'mimeType': 'image/webp',
        'fileName': 'photo.jpg',
        'sizeBytes': 5000,
      });
      expect(a, isNotNull);
      expect(a!.id, 'att-1');
    });
  });
}
