import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SettingsProfile } from '@/features/settings';
import { getAdminSecurityOverview } from '@/features/settings/data/security-adapter';

export default async function SettingsPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const securityOverview = await getAdminSecurityOverview();

  return (
    <AdminShell title="Settings" activeItem="settings" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SettingsProfile initialSessions={securityOverview.sessions} initialActivity={securityOverview.activity} />
    </AdminShell>
  );
}
