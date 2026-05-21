import { NotificationType } from '../prisma-client';

/**
 * FCM `data` map is string-only. Mirrors [NotificationDispatcherService] outbox payload.
 */
export function buildFcmDataPayload(
  notificationId: string,
  type: NotificationType,
  data?: Record<string, unknown>,
  options?: { unreadCount?: number; title?: string; body?: string },
): Record<string, string> {
  return {
    notificationId,
    type: String(type),
    notificationType: String(type),
    ...(options?.title != null && options.title.length > 0
      ? { title: options.title }
      : {}),
    ...(options?.body != null && options.body.length > 0
      ? { body: options.body }
      : {}),
    ...(options?.unreadCount !== undefined
      ? { unreadCount: String(options.unreadCount) }
      : {}),
    ...(data
      ? Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, v == null ? '' : String(v)]),
        )
      : {}),
  };
}
