import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { GamificationWorkspace, getGamificationConfig, getWeeklyRankings } from '@/features/gamification';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export default async function GamificationPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['gamification:read']);
  const t = await getTranslations('gamification');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  try {
    const [config, rankings] = await Promise.all([getGamificationConfig(), getWeeklyRankings()]);
    return (
      <AdminShell title={t('pageTitle')} activeItem="gamification" initialSidebarCollapsed={initialSidebarCollapsed}>
        <GamificationWorkspace initialConfig={config} initialRankings={rankings} />
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadGamification' });
    return (
      <AdminShell title={t('pageTitle')} activeItem="gamification" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
