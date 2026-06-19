import 'server-only';

import Link from 'next/link';
import { getTranslations } from 'next-intl/server';
import { Badge } from '@/components/ui';
import { getApiOrigin } from '@/lib/api';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { hasPermission } from '@/lib/auth/rbac/server';
import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import styles from './operations-degraded-banner.module.css';

type PushHealth = {
  status: 'ok' | 'degraded' | 'disabled';
  alerts: string[];
};

export async function OperationsDegradedBanner() {
  let profile: { role: string };
  try {
    profile = await serverAuthenticatedFetch<{ role: string }>('/auth/me', { method: 'GET' });
  } catch {
    return null;
  }

  if (!hasPermission(profile.role, ADMIN_PERMISSIONS['operations:read'])) {
    return null;
  }

  let health: PushHealth | null = null;
  try {
    const response = await fetch(`${getApiOrigin()}/health/push`, {
      cache: 'no-store',
      signal: AbortSignal.timeout(5_000),
    });
    if (response.ok) {
      health = (await response.json()) as PushHealth;
    }
  } catch {
    return null;
  }

  if (health == null || health.status === 'ok' || health.status === 'disabled') {
    return null;
  }

  const t = await getTranslations('operations');

  return (
    <Link href="/dashboard/operations" className={styles.banner}>
      <Badge tone="warning">{t('status.degraded')}</Badge>
      <span>{t('dashboardOpsBanner.message', { count: health.alerts.length })}</span>
    </Link>
  );
}
