import { Prisma } from '../prisma-client';

export const EVENT_CHAT_MESSAGE_SELECT = {
  id: true,
  eventId: true,
  createdAt: true,
  body: true,
  deletedAt: true,
  replyToId: true,
  authorId: true,
  editedAt: true,
  isPinned: true,
  pinnedAt: true,
  pinnedById: true,
  messageType: true,
  systemPayload: true,
  locationLat: true,
  locationLng: true,
  locationLabel: true,
  author: {
    select: { id: true, firstName: true, lastName: true, avatarObjectKey: true },
  },
  pinnedBy: {
    select: { id: true, firstName: true, lastName: true },
  },
  replyTo: {
    select: { id: true, body: true, deletedAt: true, bodyEncrypted: true },
  },
  bodyEncrypted: true,
  clientMessageId: true,
  attachments: {
    select: {
      id: true,
      url: true,
      mimeType: true,
      fileName: true,
      sizeBytes: true,
      width: true,
      height: true,
      duration: true,
      thumbnailUrl: true,
    },
  },
} satisfies Prisma.EventChatMessageSelect;

export type EventChatMessageRow = Prisma.EventChatMessageGetPayload<{
  select: typeof EVENT_CHAT_MESSAGE_SELECT;
}>;
