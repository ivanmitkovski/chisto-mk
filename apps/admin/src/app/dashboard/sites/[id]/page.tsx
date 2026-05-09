import { cookies } from 'next/headers';
import { notFound } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { getSiteDetail } from '@/features/sites/data/sites-adapter';
import { SiteStatusForm } from '@/app/dashboard/sites/[id]/site-status-form';

type PageProps = { params: Promise<{ id: string }> };

export default async function SiteDetailPage(props: PageProps) {
  const { id } = await props.params;
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let site: Awaited<ReturnType<typeof getSiteDetail>>;
  try {
    site = await getSiteDetail(id);
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'SITE_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    return (
      <AdminShell title="Site" activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load site." />
      </AdminShell>
    );
  }

  const s = site as {
    id: string;
    status: string;
    isArchivedByAdmin?: boolean;
    archiveReason?: string | null;
    latitude: number;
    longitude: number;
    description: string | null;
    createdAt: string;
    reports?: unknown[];
  };
  if (!s?.id) {
    notFound();
  }
  const reportCount = Array.isArray(s.reports) ? s.reports.length : 0;

  return (
    <AdminShell title="Site detail" activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SiteStatusForm
        siteId={s.id}
        initialStatus={s.status}
        initialArchivedByAdmin={Boolean(s.isArchivedByAdmin)}
        initialArchiveReason={s.archiveReason ?? null}
        latitude={s.latitude}
        longitude={s.longitude}
        description={s.description}
        reportCount={reportCount}
        createdAt={s.createdAt}
      />
    </AdminShell>
  );
}
