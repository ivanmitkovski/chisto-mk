import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { BroadcastsWorkspace, listBroadcastCampaigns } from '@/features/broadcasts';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export default async function BroadcastsPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['notifications:read']);
  const t = await getTranslations('broadcasts');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  try {
    const campaigns = await listBroadcastCampaigns();
    return (
      <AdminShell title={t('pageTitle')} activeItem="broadcasts" initialSidebarCollapsed={initialSidebarCollapsed}>
        <BroadcastsWorkspace initialCampaigns={campaigns} />
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadBroadcasts' });
    return (
      <AdminShell title={t('pageTitle')} activeItem="broadcasts" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
