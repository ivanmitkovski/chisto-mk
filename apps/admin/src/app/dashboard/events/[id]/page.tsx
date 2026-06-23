import { notFound, redirect } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { getCleanupEventDeclineReason, getCleanupEventDetail } from '@/features/events/data/events-adapter';
import { EventDetailView } from '@/features/events';
import { SectionRefreshButton } from '@/features/events';
import { canWriteCleanupEvents } from '@/features/events';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = { params: Promise<{ id: string }> };

export default async function EventDetailPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['events:read']);
  const { id } = await props.params;
  const tEvents = await getTranslations('events');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  let event: Awaited<ReturnType<typeof getCleanupEventDetail>>;
  let declineReason: string | null = null;
  let declineReasonLoadError: string | null = null;
  let canWriteCleanupEventsFlag = false;
  try {
    const [detail, me] = await Promise.all([getCleanupEventDetail(id), getMeProfile()]);
    event = detail;
    if (detail.status === 'DECLINED' && !detail.declineReason?.trim()) {
      try {
        declineReason = await getCleanupEventDeclineReason(id);
      } catch (declineError) {
        declineReasonLoadError = await handleServerLoadError(declineError, {
          fallbackMessageKey: 'unableToLoadDeclineReason',
        });
      }
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
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadEvent' });
    return (
      <AdminShell
        title={tEvents('detailTitle')}
        activeItem="events"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <SectionState variant="error" message={message}>
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
      title={tEvents('detailTitle')}
      activeItem="events"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <EventDetailView
        event={event}
        canWriteCleanupEvents={canWriteCleanupEventsFlag}
        declineReason={declineReason}
        {...(declineReasonLoadError ? { declineReasonLoadError } : {})}
      />
    </AdminShell>
  );
}
