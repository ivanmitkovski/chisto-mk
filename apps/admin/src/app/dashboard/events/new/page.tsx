import type { Metadata } from 'next';
import { notFound, redirect } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { ApiError } from '@/lib/api';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { getSiteDetail } from '@/features/sites/data/sites-adapter';
import { canWriteCleanupEvents } from '@/features/events';
import { CreateEventForm } from '@/features/events';

type PageProps = {
  searchParams: Promise<{ siteId?: string }>;
};

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations('events');
  return { title: t('createTitle') };
}

export default async function NewEventPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['events:read']);
  const tEvents = await getTranslations('events');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const params = await props.searchParams;
  const siteId = params.siteId?.trim() ?? '';

  if (!siteId) {
    redirect('/dashboard/sites');
  }

  let canWrite = false;
  let sitePreview: Awaited<ReturnType<typeof getSiteDetail>> | null = null;
  try {
    const [me, site] = await Promise.all([getMeProfile(), getSiteDetail(siteId)]);
    canWrite = canWriteCleanupEvents(me.role);
    sitePreview = site;
  } catch (error) {
    if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
      redirect('/login');
    }
    if (error instanceof ApiError && error.status === 404) {
      notFound();
    }
    redirect('/dashboard/sites');
  }
  if (!canWrite) {
    redirect('/dashboard/events');
  }
  if (!sitePreview || typeof sitePreview !== 'object' || !('id' in sitePreview)) {
    notFound();
  }

  const site = sitePreview as {
    id: string;
    latitude: number;
    longitude: number;
    description: string | null;
    status: string;
    reportCount?: number;
  };

  return (
    <AdminShell
      title={tEvents('createTitle')}
      activeItem="events"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <CreateEventForm
        siteId={site.id}
        sitePreview={{
          id: site.id,
          latitude: site.latitude,
          longitude: site.longitude,
          description: site.description,
          status: site.status,
          reportCount: site.reportCount ?? 0,
        }}
      />
    </AdminShell>
  );
}
