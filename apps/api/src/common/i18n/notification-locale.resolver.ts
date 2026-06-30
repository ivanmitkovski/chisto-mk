import type { PrismaService } from '../../prisma/prisma.service';
import { DEFAULT_APP_LOCALE, normalizeAppLocale, type AppLocale } from './app-locale';

function localeFromAcceptLanguageHint(acceptLanguageHint?: string): AppLocale | null {
  const trimmed = acceptLanguageHint?.trim();
  if (!trimmed) {
    return null;
  }
  return normalizeAppLocale(trimmed);
}

/**
 * Resolves notification copy locale for one user:
 * 1. `User.locale` (authoritative, from profile / language picker)
 * 2. Most recently seen active device token locale
 * 3. `Accept-Language` hint when present
 * 4. Default (`mk`)
 */
export async function resolveUserNotificationLocale(
  prisma: PrismaService,
  userId: string,
  acceptLanguageHint?: string,
): Promise<AppLocale> {
  const map = await userLocalesByUserId(prisma, [userId], acceptLanguageHint);
  return map.get(userId) ?? DEFAULT_APP_LOCALE;
}

/**
 * Resolves notification copy locale per user:
 * 1. `User.locale` (authoritative, from profile / language picker)
 * 2. Most recently seen active device token locale
 * 3. `Accept-Language` hint when present (batch only, for users without steps 1–2)
 * 4. Default (`mk`)
 */
export async function userLocalesByUserId(
  prisma: PrismaService,
  userIds: string[],
  acceptLanguageHint?: string,
): Promise<Map<string, AppLocale>> {
  const unique = [...new Set(userIds)].filter((id) => id.length > 0);
  const out = new Map<string, AppLocale>();
  if (unique.length === 0) {
    return out;
  }

  const users = await prisma.user.findMany({
    where: { id: { in: unique } },
    select: { id: true, locale: true },
  });
  for (const u of users) {
    if (u.locale?.trim()) {
      out.set(u.id, normalizeAppLocale(u.locale));
    }
  }

  const missing = unique.filter((id) => !out.has(id));
  if (missing.length > 0) {
    const tokens = await prisma.userDeviceToken.findMany({
      where: { userId: { in: missing }, revokedAt: null },
      orderBy: { lastSeenAt: 'desc' },
      select: { userId: true, locale: true },
    });
    for (const t of tokens) {
      if (!out.has(t.userId)) {
        out.set(t.userId, normalizeAppLocale(t.locale));
      }
    }
  }

  const hintLocale = localeFromAcceptLanguageHint(acceptLanguageHint);
  for (const id of unique) {
    if (!out.has(id)) {
      out.set(id, hintLocale ?? DEFAULT_APP_LOCALE);
    }
  }
  return out;
}

/** @deprecated Use {@link userLocalesByUserId} — kept for incremental migration. */
export async function notificationLocalesByUserId(
  prisma: PrismaService,
  userIds: string[],
  acceptLanguageHint?: string,
): Promise<Map<string, AppLocale>> {
  return userLocalesByUserId(prisma, userIds, acceptLanguageHint);
}

export function resolveUserLocaleFromMaps(
  userId: string,
  localeBy: Map<string, AppLocale>,
): AppLocale {
  return localeBy.get(userId) ?? DEFAULT_APP_LOCALE;
}
