import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { Card, SkeletonCard } from '@/components/ui';

export default async function EventDetailLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Cleanup event" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
      <Card padding="md">
        <div role="status" aria-label="Loading">
          <SkeletonCard lines={6} />
        </div>
      </Card>
    </AdminShell>
  );
}
