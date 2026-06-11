import { EventChatMessageType } from '../../prisma-client';
import type { AppLocale } from './app-locale';

export function eventChatSomeoneFallback(locale: AppLocale): string {
  switch (locale) {
    case 'en':
      return 'Someone';
    case 'sq':
      return 'Dikush';
    default:
      return 'Некој';
  }
}

export function eventChatMessageFallback(locale: AppLocale): string {
  switch (locale) {
    case 'en':
      return 'Message';
    case 'sq':
      return 'Mesazh';
    default:
      return 'Порака';
  }
}

export function eventChatMediaPreviewFallback(
  messageType: EventChatMessageType,
  locale: AppLocale,
  fileName?: string | null,
  locationLabel?: string | null,
): string {
  switch (messageType) {
    case EventChatMessageType.AUDIO:
      return locale === 'en'
        ? 'Voice message'
        : locale === 'sq'
          ? 'Mesazh zanor'
          : 'Гласовна порака';
    case EventChatMessageType.IMAGE:
      return locale === 'en' ? 'Photo' : locale === 'sq' ? 'Foto' : 'Фотографија';
    case EventChatMessageType.VIDEO:
      return locale === 'en' ? 'Video' : locale === 'sq' ? 'Video' : 'Видео';
    case EventChatMessageType.FILE: {
      const name = fileName?.trim();
      if (name && name.length > 0) {
        return name;
      }
      return locale === 'en' ? 'File' : locale === 'sq' ? 'Skedar' : 'Датотека';
    }
    case EventChatMessageType.LOCATION: {
      const label = locationLabel?.trim();
      if (label && label.length > 0) {
        return label;
      }
      return locale === 'en'
        ? 'Shared location'
        : locale === 'sq'
          ? 'Vendndodhje e ndarë'
          : 'Споделена локација';
    }
    case EventChatMessageType.SYSTEM:
      return locale === 'en'
        ? 'Event update'
        : locale === 'sq'
          ? 'Përditësim i ngjarjes'
          : 'Ажурирање на настан';
    case EventChatMessageType.TEXT:
    default:
      return eventChatMessageFallback(locale);
  }
}
