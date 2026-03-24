import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { getCleanupEvents, getEventsStats } from '@/features/events/data/events-adapter';
import { EventsWorkspace } from '@/features/events/components/events-workspace';

type PageProps = {
  searchParams: Promise<{ status?: string; moderationStatus?: string; page?: string }>;
};

export default async function EventsPage(props: PageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await props.searchParams;
  const page = Math.max(1, parseInt(params.page ?? '1', 10) || 1);
  const limit = 20;
  const status = (params.status === 'upcoming' || params.status === 'completed' ? params.status : undefined) as 'upcoming' | 'completed' | undefined;
  const moderationStatus = (params.moderationStatus === 'PENDING' || params.moderationStatus === 'APPROVED' || params.moderationStatus === 'DECLINED'
    ? params.moderationStatus
    : undefined) as 'PENDING' | 'APPROVED' | 'DECLINED' | undefined;

  let result: Awaited<ReturnType<typeof getCleanupEvents>>;
  let stats: Awaited<ReturnType<typeof getEventsStats>>;
  try {
    [result, stats] = await Promise.all([
      getCleanupEvents({ page, limit, ...(status ? { status } : {}), ...(moderationStatus ? { moderationStatus } : {}) }),
      getEventsStats(),
    ]);
  } catch {
    return (
      <AdminShell title="Cleanup events" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load events." />
      </AdminShell>
    );
  }

  return (
    <AdminShell title="Cleanup events" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
      <EventsWorkspace
        initialData={result.data}
        initialMeta={result.meta}
        initialStats={stats}
      />
    </AdminShell>
  );
}
