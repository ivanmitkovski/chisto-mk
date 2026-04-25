import type { PrismaService } from '../../prisma/prisma.service';
import type { EventNotificationLocale } from './event-user-notification.copy';
import { resolveEventNotificationLocaleFromDeviceLocale } from './event-user-notification.copy';

/**
 * Best-effort locale for push copy from the user's most recently seen device token.
 */
export async function notificationLocalesByUserId(
  prisma: PrismaService,
  userIds: string[],
): Promise<Map<string, EventNotificationLocale>> {
  const unique = [...new Set(userIds)].filter((id) => id.length > 0);
  const out = new Map<string, EventNotificationLocale>();
  if (unique.length === 0) {
    return out;
  }
  const tokens = await prisma.userDeviceToken.findMany({
    where: { userId: { in: unique }, revokedAt: null },
    orderBy: { lastSeenAt: 'desc' },
    select: { userId: true, locale: true },
  });
  for (const t of tokens) {
    if (!out.has(t.userId)) {
      out.set(t.userId, resolveEventNotificationLocaleFromDeviceLocale(t.locale));
    }
  }
  for (const id of unique) {
    if (!out.has(id)) {
      out.set(id, 'mk');
    }
  }
  return out;
}
