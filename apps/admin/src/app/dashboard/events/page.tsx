import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { getCleanupEvents, getEventsStats } from '@/features/events/data/events-adapter';
import { EventsWorkspace } from '@/features/events/components/events-workspace';
import { SectionRefreshButton } from '@/features/events/components/section-refresh-button';
import { canWriteCleanupEvents } from '@/features/events/lib/cleanup-events-write-access';
import { ApiError } from '@/lib/api';

type PageProps = {
  searchParams: Promise<{ status?: string; moderationStatus?: string; page?: string; q?: string }>;
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
  const qRaw = params.q?.trim() ?? '';
  const q = qRaw.length >= 2 ? qRaw : undefined;

  let result: Awaited<ReturnType<typeof getCleanupEvents>>;
  let stats: Awaited<ReturnType<typeof getEventsStats>>;
  let canWriteCleanupEventsFlag = false;
  try {
    const [me, listResult, statsResult] = await Promise.all([
      getMeProfile(),
      getCleanupEvents({
        page,
        limit,
        ...(status ? { status } : {}),
        ...(moderationStatus ? { moderationStatus } : {}),
        ...(q ? { q } : {}),
      }),
      getEventsStats(),
    ]);
    canWriteCleanupEventsFlag = canWriteCleanupEvents(me.role);
    result = listResult;
    stats = statsResult;
  } catch (error) {
    if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
      redirect('/login');
    }
    return (
      <AdminShell title="Cleanup events" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load events. Check your connection or sign in again.">
          <SectionRefreshButton />
        </SectionState>
      </AdminShell>
    );
  }

  return (
    <AdminShell title="Cleanup events" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
      <EventsWorkspace
        initialData={result.data}
        initialMeta={result.meta}
        initialStats={stats}
        canWriteCleanupEvents={canWriteCleanupEventsFlag}
      />
    </AdminShell>
  );
}
