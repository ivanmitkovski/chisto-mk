import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { CreateEventForm } from './create-event-form';

type PageProps = {
  searchParams: Promise<{ siteId?: string }>;
};

export default async function NewEventPage(props: PageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await props.searchParams;
  const siteId = params.siteId ?? '';

  if (!siteId) {
    redirect('/dashboard/sites');
  }

  return (
    <AdminShell
      title="Create cleanup event"
      activeItem="events"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <CreateEventForm siteId={siteId} />
    </AdminShell>
  );
}
