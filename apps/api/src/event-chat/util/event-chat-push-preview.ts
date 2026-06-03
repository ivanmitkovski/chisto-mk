import { EventChatMessageType } from '../../prisma-client';
import type { EventChatMessageRow } from './event-chat-message.select';

/** Non-empty preview text for FCM/inbox when message body is empty (voice, photo, etc.). */
export function buildEventChatPushPreview(
  message: Pick<
    EventChatMessageRow,
    'messageType' | 'locationLabel' | 'attachments' | 'body'
  >,
  bodyPlain: string,
): string {
  const text = bodyPlain.trim();
  if (text.length > 0) {
    return text;
  }

  const firstAttachment = message.attachments?.[0];
  const fileName = firstAttachment?.fileName?.trim();

  switch (message.messageType) {
    case EventChatMessageType.AUDIO:
      return 'Voice message';
    case EventChatMessageType.IMAGE:
      return 'Photo';
    case EventChatMessageType.VIDEO:
      return 'Video';
    case EventChatMessageType.FILE:
      return fileName && fileName.length > 0 ? fileName : 'File';
    case EventChatMessageType.LOCATION: {
      const label = message.locationLabel?.trim();
      return label && label.length > 0 ? label : 'Shared location';
    }
    case EventChatMessageType.SYSTEM:
      return 'Event update';
    case EventChatMessageType.TEXT:
    default:
      return 'Message';
  }
}
