import { EventChatMessageType } from '../../prisma-client';
import type { AppLocale } from '../../common/i18n/app-locale';
import { eventChatMediaPreviewFallback } from '../../common/i18n/event-chat-notification.copy';
import type { EventChatMessageRow } from './event-chat-message.select';

/** Non-empty preview text for FCM/inbox when message body is empty (voice, photo, etc.). */
export function buildEventChatPushPreview(
  message: Pick<
    EventChatMessageRow,
    'messageType' | 'locationLabel' | 'attachments' | 'body'
  >,
  bodyPlain: string,
  locale: AppLocale = 'en',
): string {
  const text = bodyPlain.trim();
  if (text.length > 0) {
    return text;
  }

  const firstAttachment = message.attachments?.[0];
  const fileName = firstAttachment?.fileName?.trim();

  return eventChatMediaPreviewFallback(
    message.messageType as EventChatMessageType,
    locale,
    fileName,
    message.locationLabel,
  );
}
