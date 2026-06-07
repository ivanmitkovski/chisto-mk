import type { AdminLocale } from '@/lib/preferences/admin-locale';

const MESSAGE_NAMESPACES = [
  'common',
  'nav',
  'ui',
  'auth',
  'errors',
  'settings',
  'dashboard',
  'reports',
  'moderation',
  'events',
  'sites',
  'map',
  'users',
  'team',
  'audit',
  'broadcasts',
  'gamification',
  'operations',
  'comms',
  'appConfig',
  'notifications',
  'acceptInvite',
] as const;

export type MessageNamespace = (typeof MESSAGE_NAMESPACES)[number];

export async function loadMessages(locale: AdminLocale): Promise<Record<string, unknown>> {
  const entries = await Promise.all(
    MESSAGE_NAMESPACES.map(async (namespace) => {
      const mod = await import(`./messages/${locale}/${namespace}.json`);
      return [namespace, mod.default] as const;
    }),
  );
  return Object.fromEntries(entries);
}
