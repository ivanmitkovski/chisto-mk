import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { Card, SkeletonCard } from '@/components/ui';

export default async function SiteDetailLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Site" activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
      <Card padding="md">
        <SkeletonCard lines={5} />
      </Card>
    </AdminShell>
  );
}
