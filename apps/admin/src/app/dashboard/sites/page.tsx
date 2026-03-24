import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { getSitesList, getSitesStats } from '@/features/sites/data/sites-adapter';
import { SitesWorkspace } from '@/features/sites/components/sites-workspace';

type PageProps = {
  searchParams: Promise<{ status?: string; page?: string }>;
};

export default async function SitesPage(props: PageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await props.searchParams;
  const page = Math.max(1, parseInt(params.page ?? '1', 10) || 1);
  const limit = 20;
  const status = params.status || undefined;

  let result: Awaited<ReturnType<typeof getSitesList>>;
  let stats: Awaited<ReturnType<typeof getSitesStats>>;
  try {
    [result, stats] = await Promise.all([
      getSitesList({ page, limit, ...(status ? { status } : {}) }),
      getSitesStats(),
    ]);
  } catch {
    return (
      <AdminShell title="Sites" activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load sites." />
      </AdminShell>
    );
  }

  return (
    <AdminShell title="Sites" activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SitesWorkspace
        initialData={result.data}
        initialMeta={result.meta}
        initialStats={stats}
      />
    </AdminShell>
  );
}
