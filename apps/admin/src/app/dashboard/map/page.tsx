import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SitesMap } from '@/features/map';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export const metadata: Metadata = {
  title: 'Map',
};

export default async function MapPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['map:read']);
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell
      title="Map"
      activeItem="map"
      initialSidebarCollapsed={initialSidebarCollapsed}
      contentMode="immersive"
    >
      <SitesMap />
    </AdminShell>
  );
}
