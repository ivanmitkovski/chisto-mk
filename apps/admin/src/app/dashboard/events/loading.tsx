import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SkeletonTable } from '@/components/ui';

export default async function EventsLoading() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Cleanup events" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SkeletonTable rows={8} cols={4} />
    </AdminShell>
  );
}
