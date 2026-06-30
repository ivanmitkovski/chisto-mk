import { Suspense } from 'react';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { getCleanupEvents } from '@/features/events/data/events-adapter';
import { EventsWorkspace } from '@/features/events';
import { SectionRefreshButton } from '@/features/events';
import { canWriteCleanupEvents } from '@/features/events';
import {
  EventsStatsFallback,
  EventsStatsSection,
} from '@/features/events/components/events-async-sections';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = {
  searchParams: Promise<{ status?: string; moderationStatus?: string; page?: string; q?: string }>;
};

function buildModerationQueueHref(params: {
  status?: string;
  moderationStatus?: string;
  page?: string;
  q?: string;
}): string {
  const sp = new URLSearchParams();
  sp.set('moderationStatus', 'PENDING');
  sp.set('page', '1');
  if (params.status) sp.set('status', params.status);
  if (params.q) sp.set('q', params.q);
  return `/dashboard/events?${sp.toString()}`;
}

export default async function EventsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['events:read']);
  const tNav = await getTranslations('nav');
  const { initialSidebarCollapsed } = await readDashboardShellState();
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
  let canWriteCleanupEventsFlag = false;
  try {
    const [me, listResult] = await Promise.all([
      getMeProfile(),
      getCleanupEvents({
        page,
        limit,
        ...(status ? { status } : {}),
        ...(moderationStatus ? { moderationStatus } : {}),
        ...(q ? { q } : {}),
      }),
    ]);
    canWriteCleanupEventsFlag = canWriteCleanupEvents(me.role);
    result = listResult;
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

  const moderationQueueHref = buildModerationQueueHref(params);
  const statsSection = (
    <Suspense fallback={<EventsStatsFallback />}>
      <EventsStatsSection moderationQueueHref={moderationQueueHref} />
    </Suspense>
  );

  return (
    <AdminShell title={tNav('events')} activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
      <EventsWorkspace
        initialData={result.data}
        initialMeta={result.meta}
        statsSection={statsSection}
        canWriteCleanupEvents={canWriteCleanupEventsFlag}
      />
    </AdminShell>
  );
}
