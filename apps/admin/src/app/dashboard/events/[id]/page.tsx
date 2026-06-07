import { cookies } from 'next/headers';
import { notFound, redirect } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getMeProfile } from '@/features/auth';
import { getCleanupEventDeclineReason, getCleanupEventDetail } from '@/features/events';
import { EventDetailView } from '@/features/events';
import { SectionRefreshButton } from '@/features/events';
import { canWriteCleanupEvents } from '@/features/events';

type PageProps = { params: Promise<{ id: string }> };

export default async function EventDetailPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['events:read']);
  const { id } = await props.params;
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let event: Awaited<ReturnType<typeof getCleanupEventDetail>>;
  let declineReason: string | null = null;
  let canWriteCleanupEventsFlag = false;
  try {
    const [detail, me] = await Promise.all([getCleanupEventDetail(id), getMeProfile()]);
    event = detail;
    if (detail.status === 'DECLINED' && !detail.declineReason?.trim()) {
      declineReason = await getCleanupEventDeclineReason(id).catch(() => null);
    } else {
      declineReason = detail.declineReason?.trim() || null;
    }
    canWriteCleanupEventsFlag = canWriteCleanupEvents(me.role);
  } catch (error) {
    if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
      redirect('/login');
    }
    if (error instanceof ApiError && (error.code === 'CLEANUP_EVENT_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    return (
      <AdminShell title="Event" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load event. Check your connection or sign in again.">
          <SectionRefreshButton />
        </SectionState>
      </AdminShell>
    );
  }

  if (!event?.id) {
    notFound();
  }

  return (
    <AdminShell
      title="Cleanup event"
      activeItem="events"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <EventDetailView
        event={event}
        canWriteCleanupEvents={canWriteCleanupEventsFlag}
        declineReason={declineReason}
      />
    </AdminShell>
  );
}
