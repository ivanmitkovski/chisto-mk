import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import { getMeProfile } from '@/features/auth';
import { getCleanupEvents, getEventsStats } from '@/features/events';
import { EventsWorkspace } from '@/features/events';
import { SectionRefreshButton } from '@/features/events';
import { canWriteCleanupEvents } from '@/features/events';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = {
  searchParams: Promise<{ status?: string; moderationStatus?: string; page?: string; q?: string }>;
};

export default async function EventsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['events:read']);
  const tNav = await getTranslations('nav');
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
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadEvents' });
    return (
      <AdminShell title={tNav('events')} activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message}>
          <SectionRefreshButton />
        </SectionState>
      </AdminShell>
    );
  }

  return (
    <AdminShell title={tNav('events')} activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
      <EventsWorkspace
        initialData={result.data}
        initialMeta={result.meta}
        initialStats={stats}
        canWriteCleanupEvents={canWriteCleanupEventsFlag}
      />
    </AdminShell>
  );
}
