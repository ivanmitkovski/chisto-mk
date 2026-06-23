import type { AdminLocale } from '@/lib/preferences/admin-locale';

export const CORE_MESSAGE_NAMESPACES = [
  'common',
  'nav',
  'ui',
  'auth',
  'errors',
  'commandPalette',
] as const;

export const ALL_MESSAGE_NAMESPACES = [
  ...CORE_MESSAGE_NAMESPACES,
  'settings',
  'dashboard',
  'reports',
  'moderation',
  'events',
  'sites',
  'resolutions',
  'map',
  'users',
  'team',
  'audit',
  'broadcasts',
  'gamification',
  'operations',
  'activeUsers',
  'comms',
  'appConfig',
  'notifications',
  'acceptInvite',
  'news',
] as const;

export type MessageNamespace = (typeof ALL_MESSAGE_NAMESPACES)[number];

/** All feature namespaces used anywhere under /dashboard (client nav + shared shell). */
export const DASHBOARD_SCOPED_NAMESPACES = [
  'dashboard',
  'reports',
  'operations',
  'notifications',
  'settings',
  'activeUsers',
  'map',
  'events',
  'sites',
  'resolutions',
  'users',
  'moderation',
  'team',
  'audit',
  'broadcasts',
  'gamification',
  'appConfig',
  'comms',
  'news',
] as const satisfies readonly MessageNamespace[];

const ROUTE_EXTRA_NAMESPACES: Record<string, MessageNamespace[]> = {
  '/dashboard': ['dashboard', 'reports', 'operations', 'notifications'],
  '/dashboard/active-users': ['activeUsers', 'dashboard', 'map'],
  '/dashboard/reports': ['reports'],
  '/dashboard/events': ['events', 'sites'],
  '/dashboard/sites': ['sites', 'resolutions'],
  '/dashboard/resolutions': ['resolutions', 'sites'],
  '/dashboard/map': ['map', 'sites'],
  '/dashboard/users': ['users', 'broadcasts'],
  '/dashboard/moderation': ['moderation'],
  '/dashboard/settings': ['settings'],
  '/dashboard/team': ['team'],
  '/dashboard/audit': ['audit'],
  '/dashboard/broadcasts': ['broadcasts', 'users'],
  '/dashboard/operations': ['operations'],
  '/dashboard/gamification': ['gamification'],
  '/dashboard/notifications': ['notifications'],
  '/dashboard/app-config': ['appConfig'],
  '/dashboard/comms': ['comms'],
  '/dashboard/news': ['news'],
  '/login': ['auth'],
  '/accept-invite': ['acceptInvite', 'auth'],
};

export function getNamespacesForPathname(pathname: string): MessageNamespace[] {
  const normalized = pathname.split('?')[0] ?? pathname;

  if (normalized.startsWith('/dashboard')) {
    return [...new Set<MessageNamespace>([...CORE_MESSAGE_NAMESPACES, ...DASHBOARD_SCOPED_NAMESPACES])];
  }

  const extras = new Set<MessageNamespace>();

  for (const [prefix, namespaces] of Object.entries(ROUTE_EXTRA_NAMESPACES)) {
    if (normalized === prefix || normalized.startsWith(`${prefix}/`)) {
      for (const ns of namespaces) extras.add(ns);
    }
  }

  if (extras.size === 0) {
    return [...ALL_MESSAGE_NAMESPACES];
  }

  const merged = new Set<MessageNamespace>([...CORE_MESSAGE_NAMESPACES, ...extras]);
  return [...merged];
}

async function loadNamespace(locale: AdminLocale, namespace: MessageNamespace) {
  const mod = await import(`./messages/${locale}/${namespace}.json`);
  return [namespace, mod.default] as const;
}

export async function loadMessages(
  locale: AdminLocale,
  namespaces: readonly MessageNamespace[] = ALL_MESSAGE_NAMESPACES,
): Promise<Record<string, unknown>> {
  const entries = await Promise.all(namespaces.map((namespace) => loadNamespace(locale, namespace)));
  return Object.fromEntries(entries);
}

/** Loads all namespaces (login, error pages, unknown routes). */
export async function loadAllMessages(locale: AdminLocale): Promise<Record<string, unknown>> {
  return loadMessages(locale, ALL_MESSAGE_NAMESPACES);
}
