import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import styles from './map-loading.module.css';

export default async function MapLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell
      title="Map"
      activeItem="map"
      initialSidebarCollapsed={initialSidebarCollapsed}
      contentMode="immersive"
    >
      <div className={styles.mapSkeleton} aria-busy="true" aria-live="polite" />
    </AdminShell>
  );
}
