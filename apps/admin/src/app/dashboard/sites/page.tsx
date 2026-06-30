import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { SitesWorkspace } from '@/features/sites';
import { getSitesList, getSitesStats } from '@/features/sites/data/sites-adapter';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = {
  searchParams: Promise<{ status?: string; page?: string; search?: string }>;
};

export default async function SitesPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['sites:read']);
  const tNav = await getTranslations('nav');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const params = await props.searchParams;
  const page = Math.max(1, parseInt(params.page ?? '1', 10) || 1);
  const limit = 20;
  const status = params.status || undefined;
  const search = params.search?.trim() || undefined;

  let result: Awaited<ReturnType<typeof getSitesList>>;
  let stats: Awaited<ReturnType<typeof getSitesStats>>;
  try {
    [result, stats] = await Promise.all([
      getSitesList({ page, limit, ...(status ? { status } : {}), ...(search ? { search } : {}) }),
      getSitesStats(),
    ]);
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadSites' });
    return (
      <AdminShell title={tNav('sites')} activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }

  return (
    <AdminShell title={tNav('sites')} activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SitesWorkspace
        initialData={result.data}
        initialMeta={result.meta}
        initialStats={stats}
      />
    </AdminShell>
  );
}
