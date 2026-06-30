import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { loadTeamWorkspace, TeamWorkspace } from '@/features/team';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export default async function TeamPage() {
  const tNav = await getTranslations('nav');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  await requirePagePermission(ADMIN_PERMISSIONS['team:read']);

  try {
    const [{ staff, invites }, me] = await Promise.all([loadTeamWorkspace(), getMeProfile()]);
    return (
      <AdminShell title={tNav('team')} activeItem="team" initialSidebarCollapsed={initialSidebarCollapsed}>
        <TeamWorkspace initialStaff={staff} initialInvites={invites} currentUserId={me.id} />
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadTeam' });
    return (
      <AdminShell title={tNav('team')} activeItem="team" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
