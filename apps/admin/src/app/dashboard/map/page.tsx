import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SitesMap } from '@/features/map/components/sites-map-client';

export const metadata: Metadata = {
  title: 'Map',
};

export default async function MapPage() {
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
