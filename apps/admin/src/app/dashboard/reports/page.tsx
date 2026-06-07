import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { getReportsPage, getReportsQueueSummary, ReportsPageClient } from '@/features/reports';
import type { SortDirection, SortKey } from '@/features/reports/types';
import { VALID_SORT_KEYS } from '@/features/reports/components/reports-list-utils';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export const metadata: Metadata = {
  title: 'Reports',
};

type ReportsPageProps = {
  searchParams: Promise<{
    siteId?: string;
    page?: string;
    status?: string;
    search?: string;
    q?: string;
    sort?: string;
    dir?: string;
    duplicatesOnly?: string;
  }>;
};

export default async function ReportsPage(props: ReportsPageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['reports:read']);
  const tNav = await getTranslations('nav');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const params = await props.searchParams;
  const siteId = params.siteId;
  const page = Math.max(1, Number.parseInt(params.page ?? '1', 10) || 1);
  const status = params.status && params.status !== 'ALL' ? params.status : undefined;
  const search = params.search ?? params.q;
  const sortParam = params.sort;
  const sort =
    sortParam && VALID_SORT_KEYS.includes(sortParam as SortKey) ? (sortParam as SortKey) : undefined;
  const dir: SortDirection | undefined =
    params.dir === 'asc' ? 'asc' : params.dir === 'desc' ? 'desc' : undefined;
  const duplicatesOnly = params.duplicatesOnly === 'true' || params.duplicatesOnly === '1';

  let result: Awaited<ReturnType<typeof getReportsPage>>;
  let queueSummary: Awaited<ReturnType<typeof getReportsQueueSummary>>;
  try {
    [result, queueSummary] = await Promise.all([
      getReportsPage({
        page,
        limit: 50,
        ...(status ? { status } : {}),
        ...(search ? { search } : {}),
        ...(siteId ? { siteId } : {}),
        ...(sort ? { sort } : {}),
        ...(dir ? { dir } : {}),
        ...(duplicatesOnly ? { duplicatesOnly: true } : {}),
      }),
      getReportsQueueSummary(),
    ]);
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadReports' });
    return (
      <AdminShell title={tNav('reports')} activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }

  return (
    <AdminShell title={tNav('reports')} activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <ReportsPageClient
        reports={result.data}
        meta={result.meta}
        queueSummary={queueSummary}
        initialSearch={search ?? ''}
        {...(siteId ? { siteIdFilter: siteId } : {})}
      />
    </AdminShell>
  );
}
