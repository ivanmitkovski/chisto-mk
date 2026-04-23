import { NotificationType } from '../prisma-client';

/**
 * FCM `data` map is string-only. Mirrors [NotificationDispatcherService] outbox payload.
 */
export function buildFcmDataPayload(
  notificationId: string,
  type: NotificationType,
  data?: Record<string, unknown>,
): Record<string, string> {
  return {
    notificationId,
    type: String(type),
    ...(data
      ? Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, v == null ? '' : String(v)]),
        )
      : {}),
  };
}
