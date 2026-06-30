import { notFound } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getSiteDetail } from '@/features/sites/data/sites-adapter';
import { SiteDetailClient } from '@/features/sites';
import { getSiteResolutionsForSite } from '@/features/sites/data/resolutions-adapter';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = { params: Promise<{ id: string }> };

export default async function SiteDetailPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['sites:read']);
  const { id } = await props.params;
  const tSites = await getTranslations('sites');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  let site: Awaited<ReturnType<typeof getSiteDetail>>;
  let resolutions: Awaited<ReturnType<typeof getSiteResolutionsForSite>>;
  try {
    [site, resolutions] = await Promise.all([getSiteDetail(id), getSiteResolutionsForSite(id)]);
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'SITE_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadSite' });
    return (
      <AdminShell
        title={tSites('detailTitle')}
        activeItem="sites"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <SectionState variant="error" message={message} />
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
    <AdminShell
      title={tSites('detailPageTitle')}
      activeItem="sites"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <SiteDetailClient
        siteId={s.id}
        initialStatus={s.status}
        initialArchivedByAdmin={Boolean(s.isArchivedByAdmin)}
        initialArchiveReason={s.archiveReason ?? null}
        latitude={s.latitude}
        longitude={s.longitude}
        description={s.description}
        reportCount={reportCount}
        createdAt={s.createdAt}
        initialResolutions={resolutions.data}
      />
    </AdminShell>
  );
}
