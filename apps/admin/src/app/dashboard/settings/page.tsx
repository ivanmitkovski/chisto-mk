import type { Metadata } from 'next';
import { Suspense } from 'react';
import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { SettingsConsole } from '@/features/settings/components/settings-console';
import { getAdminSecurityOverview } from '@/features/settings/data/security-adapter';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { getSystemConfig } from '@/features/settings/data/config-adapter';
import { getFeatureFlags } from '@/features/settings/data/feature-flags-adapter';

export const metadata: Metadata = {
  title: 'Settings',
};

export default async function SettingsPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let payload: {
    me: Awaited<ReturnType<typeof getMeProfile>>;
    security: Awaited<ReturnType<typeof getAdminSecurityOverview>>;
    config: Awaited<ReturnType<typeof getSystemConfig>>;
    flags: Awaited<ReturnType<typeof getFeatureFlags>>;
  };

  try {
    const [me, security, config, flags] = await Promise.all([
      getMeProfile(),
      getAdminSecurityOverview(),
      getSystemConfig(),
      getFeatureFlags(),
    ]);
    payload = { me, security, config, flags };
  } catch {
    return (
      <AdminShell title="Settings" activeItem="settings" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState
          variant="error"
          message="Unable to load settings. Please try again or sign in again."
        />
      </AdminShell>
    );
  }

  return (
    <AdminShell title="Settings" activeItem="settings" initialSidebarCollapsed={initialSidebarCollapsed}>
      <Suspense
        fallback={
          <p style={{ margin: 0, color: 'var(--text-secondary)', fontSize: 'var(--font-size-sm)' }}>
            Loading settings…
          </p>
        }
      >
        <SettingsConsole
          initialMe={payload.me}
          initialSessions={payload.security.sessions}
          initialActivity={payload.security.activity}
          initialConfig={payload.config}
          initialFlags={payload.flags}
        />
      </Suspense>
    </AdminShell>
  );
}
