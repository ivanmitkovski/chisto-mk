import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import { getSitesList, getSitesStats } from '@/features/sites';
import { SitesWorkspace } from '@/features/sites';

type PageProps = {
  searchParams: Promise<{ status?: string; page?: string; search?: string }>;
};

export default async function SitesPage(props: PageProps) {
  const tNav = await getTranslations('nav');
  const tErrors = await getTranslations('errors');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
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
  } catch {
    return (
      <AdminShell title={tNav('sites')} activeItem="sites" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={tErrors('unableToLoadSites')} />
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
