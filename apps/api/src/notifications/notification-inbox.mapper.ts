import { NotificationType } from '../prisma-client';
import { NotificationActorDto } from './dto/notification-actor.dto';

export type NotificationListItem = {
  id: string;
  title: string;
  body: string;
  type: NotificationType;
  isRead: boolean;
  data: unknown;
  createdAt: string;
  sentAt: string | null;
  threadKey: string | null;
  groupKey: string | null;
  archivedAt: string | null;
  actor?: NotificationActorDto | null;
};

export const inboxListSelect = {
  id: true,
  title: true,
  body: true,
  type: true,
  isRead: true,
  data: true,
  createdAt: true,
  sentAt: true,
  threadKey: true,
  groupKey: true,
  archivedAt: true,
} as const;

export function extractActorUserId(data: unknown): string | null {
  if (data == null || typeof data !== 'object') return null;
  const record = data as Record<string, unknown>;
  const raw = record['actorUserId'] ?? record['highlightActorUserId'];
  if (typeof raw !== 'string' || raw.trim().length === 0) return null;
  return raw.trim();
}

export function mapInboxRow(
  n: {
    id: string;
    title: string;
    body: string;
    type: NotificationType;
    isRead: boolean;
    data: unknown;
    createdAt: Date;
    sentAt: Date | null;
    threadKey: string | null;
    groupKey: string | null;
    archivedAt: Date | null;
  },
  actorById: Map<string, NotificationActorDto>,
): NotificationListItem {
  const actorUserId = extractActorUserId(n.data);
  const actor = actorUserId != null ? actorById.get(actorUserId) ?? null : null;
  return {
    id: n.id,
    title: n.title,
    body: n.body,
    type: n.type,
    isRead: n.isRead,
    data: n.data,
    createdAt: n.createdAt.toISOString(),
    sentAt: n.sentAt?.toISOString() ?? null,
    threadKey: n.threadKey,
    groupKey: n.groupKey,
    archivedAt: n.archivedAt?.toISOString() ?? null,
    ...(actor ? { actor } : {}),
  };
}

export function collapseByGroupKey(
  items: NotificationListItem[],
): Array<NotificationListItem & { groupCount: number }> {
  if (items.length === 0) return [];
  const result: Array<NotificationListItem & { groupCount: number }> = [];
  let current = items[0];
  let groupCount = 1;
  const WINDOW_MS = 24 * 60 * 60 * 1000;

  for (let i = 1; i < items.length; i++) {
    const item = items[i];
    const sameGroup =
      current.groupKey != null &&
      item.groupKey === current.groupKey &&
      Math.abs(new Date(current.createdAt).getTime() - new Date(item.createdAt).getTime()) <
        WINDOW_MS;

    if (sameGroup) {
      groupCount++;
    } else {
      result.push({ ...current, groupCount });
      current = item;
      groupCount = 1;
    }
  }
  result.push({ ...current, groupCount });
  return result;
}
