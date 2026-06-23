import { adminBrowserFetch } from '@/lib/api/admin-browser-api';
import { fetchSitesList, fetchUsers } from '@/lib/api/admin-api-client';
import { ADMIN_PERMISSIONS, type AdminPermission } from '@/lib/auth/rbac/permissions';
import type { IconName } from '@/components/ui';
import type { CommandDefinition } from './types';

export type EntitySearchState = {
  loading: boolean;
  errors: Partial<Record<'users' | 'reports' | 'sites', string>>;
};

type EntitySearchRow = {
  id: string;
  group: 'users' | 'reports' | 'sites';
  label: string;
  description?: string;
  href: string;
  icon: IconName;
};

type ReportsListResponse = {
  data: Array<{
    id: string;
    reportNumber: string;
    name: string;
    location: string;
  }>;
};

const ENTITY_SEARCH_MIN_LENGTH = 2;
const ENTITY_SEARCH_LIMIT = 5;

function isPathLikeQuery(query: string): boolean {
  const q = query.trim();
  return q.startsWith('/') || q.includes('/dashboard');
}

export function shouldRunEntitySearch(query: string): boolean {
  const trimmed = query.trim();
  return trimmed.length >= ENTITY_SEARCH_MIN_LENGTH && !isPathLikeQuery(trimmed);
}

export async function fetchEntityCommands(
  query: string,
  can: (permission: AdminPermission) => boolean,
  signal: AbortSignal,
): Promise<CommandDefinition[]> {
  if (!shouldRunEntitySearch(query)) {
    return [];
  }

  const trimmed = query.trim();
  const tasks: Promise<EntitySearchRow[]>[] = [];

  if (can(ADMIN_PERMISSIONS['users:read'])) {
    tasks.push(
      fetchUsers({ search: trimmed, page: 1, limit: ENTITY_SEARCH_LIMIT })
        .then((res) =>
          res.data.map((user) => ({
            id: `entity-user-${user.id}`,
            group: 'users' as const,
            label: `${user.firstName} ${user.lastName}`.trim() || user.email,
            description: user.email,
            href: `/dashboard/users/${user.id}`,
            icon: 'user' as IconName,
          })),
        )
        .catch(() => []),
    );
  }

  if (can(ADMIN_PERMISSIONS['reports:read'])) {
    tasks.push(
      adminBrowserFetch<ReportsListResponse>(
        `/reports?page=1&limit=${ENTITY_SEARCH_LIMIT}&search=${encodeURIComponent(trimmed)}`,
      )
        .then((res) =>
          res.data.map((report) => ({
            id: `entity-report-${report.id}`,
            group: 'reports' as const,
            label: report.reportNumber,
            description: report.name || report.location,
            href: `/dashboard/reports/${report.id}`,
            icon: 'document-text' as IconName,
          })),
        )
        .catch(() => []),
    );
  }

  if (can(ADMIN_PERMISSIONS['sites:read'])) {
    tasks.push(
      fetchSitesList({ search: trimmed, page: 1, limit: ENTITY_SEARCH_LIMIT })
        .then((res) =>
          res.data.map((site) => ({
            id: `entity-site-${site.id}`,
            group: 'sites' as const,
            label: site.description?.trim() || `Site ${site.id.slice(0, 8)}`,
            description: `${site.status} · ${site.reportCount} reports`,
            href: `/dashboard/sites/${site.id}`,
            icon: 'location' as IconName,
          })),
        )
        .catch(() => []),
    );
  }

  const rows = (await Promise.all(tasks)).flat();

  if (signal.aborted) {
    return [];
  }

  return rows.map((row) => ({
    id: row.id,
    group: row.group,
    labelKey: row.label,
    ...(row.description ? { descriptionKey: row.description } : {}),
    messageNamespace: 'commandPalette' as const,
    icon: row.icon,
    href: row.href,
    action: { type: 'navigate' as const, href: row.href },
  }));
}

export { ENTITY_SEARCH_MIN_LENGTH };
