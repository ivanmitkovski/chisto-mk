import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import {
  SettingsConsole,
  getAdminSecurityOverview,
  getSystemConfig,
  getFeatureFlags,
  getModerationEmailPreferences,
} from '@/features/settings';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { hasPermission } from '@/lib/auth/rbac/require-permission';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export const metadata: Metadata = {
  title: 'Settings',
};

export default async function SettingsPage() {
  const tNav = await getTranslations('nav');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  const me = await requirePagePermission(ADMIN_PERMISSIONS['settings:read']);
  const canReadConfig = hasPermission(me.role, ADMIN_PERMISSIONS['config:write']);

  let payload: {
    me: typeof me;
    security: Awaited<ReturnType<typeof getAdminSecurityOverview>>;
    config: Awaited<ReturnType<typeof getSystemConfig>> | null;
    flags: Awaited<ReturnType<typeof getFeatureFlags>>;
    moderationEmailPrefs: Awaited<ReturnType<typeof getModerationEmailPreferences>>;
  };

  try {
    const [security, config, flags, moderationEmailPrefs] = await Promise.all([
      getAdminSecurityOverview(),
      canReadConfig ? getSystemConfig() : Promise.resolve(null),
      getFeatureFlags(),
      getModerationEmailPreferences().catch(() => []),
    ]);
    payload = { me, security, config, flags, moderationEmailPrefs };
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadSettings' });
    return (
      <AdminShell title={tNav('settings')} activeItem="settings" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }

  return (
    <AdminShell title={tNav('settings')} activeItem="settings" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SettingsConsole
        initialMe={payload.me}
        initialSessions={payload.security.sessions}
        initialActivity={payload.security.activity}
        initialConfig={payload.config ?? []}
        initialFlags={payload.flags}
        initialModerationEmailPrefs={payload.moderationEmailPrefs}
      />
    </AdminShell>
  );
}
