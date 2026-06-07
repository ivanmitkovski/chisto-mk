import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { BroadcastsWorkspace, listBroadcastCampaigns } from '@/features/broadcasts';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export default async function BroadcastsPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['notifications:broadcast']);
  const t = await getTranslations('broadcasts');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
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
