import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
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

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations('settings');
  return { title: t('pageTitle') };
}

export default async function SettingsPage() {
  const tNav = await getTranslations('nav');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  const me = await requirePagePermission(ADMIN_PERMISSIONS['settings:read']);
  const canReadConfig = hasPermission(me.role, ADMIN_PERMISSIONS['config:write']);

  let payload: {
    me: typeof me;
    security: Awaited<ReturnType<typeof getAdminSecurityOverview>>;
    config: Awaited<ReturnType<typeof getSystemConfig>> | null;
    flags: Awaited<ReturnType<typeof getFeatureFlags>>;
    moderationEmailPrefs: Awaited<ReturnType<typeof getModerationEmailPreferences>>;
    moderationEmailPrefsError: string | null;
  };

  try {
    const [security, config, flags] = await Promise.all([
      getAdminSecurityOverview(),
      canReadConfig ? getSystemConfig() : Promise.resolve(null),
      getFeatureFlags(),
    ]);
    let moderationEmailPrefs: Awaited<ReturnType<typeof getModerationEmailPreferences>> = [];
    let moderationEmailPrefsError: string | null = null;
    try {
      moderationEmailPrefs = await getModerationEmailPreferences();
    } catch (prefsError) {
      moderationEmailPrefsError = await handleServerLoadError(prefsError, {
        fallbackMessageKey: 'unableToLoadModerationEmailPrefs',
      });
    }
    payload = { me, security, config, flags, moderationEmailPrefs, moderationEmailPrefsError };
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
        {...(payload.moderationEmailPrefsError
          ? { initialModerationEmailPrefsError: payload.moderationEmailPrefsError }
          : {})}
      />
    </AdminShell>
  );
}
