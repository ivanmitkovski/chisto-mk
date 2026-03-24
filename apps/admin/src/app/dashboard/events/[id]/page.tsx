import { cookies } from 'next/headers';
import { notFound } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { getCleanupEventDetail } from '@/features/events/data/events-adapter';
import { EventDetailView } from '@/app/dashboard/events/[id]/event-detail-view';

type PageProps = { params: Promise<{ id: string }> };

export default async function EventDetailPage(props: PageProps) {
  const { id } = await props.params;
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let event: Awaited<ReturnType<typeof getCleanupEventDetail>>;
  try {
    event = await getCleanupEventDetail(id);
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'CLEANUP_EVENT_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    return (
      <AdminShell title="Event" activeItem="events" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load event." />
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
      <EventDetailView event={event} />
    </AdminShell>
  );
}
