import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { MapWorkspaceLazy } from '@/features/map/components/map-workspace-lazy';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations('map');
  return { title: t('pageTitle') };
}

export default async function MapPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['map:read']);
  const tNav = await getTranslations('nav');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  return (
    <AdminShell
      title={tNav('map')}
      activeItem="map"
      initialSidebarCollapsed={initialSidebarCollapsed}
      contentMode="immersive"
    >
      <MapWorkspaceLazy />
    </AdminShell>
  );
}
