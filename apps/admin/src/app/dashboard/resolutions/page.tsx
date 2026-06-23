import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getSiteResolutionsPage } from '@/features/sites/data/resolutions-adapter';
import { ResolutionsWorkspace } from '@/features/sites/components/resolutions-workspace';
import type { SiteResolutionStatus } from '@/features/sites/data/resolutions-adapter';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = {
  searchParams: Promise<{ page?: string; status?: string; siteId?: string }>;
};

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations('resolutions');
  return { title: t('pageTitle') };
}

export default async function ResolutionsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['sites:read']);
  const tNav = await getTranslations('nav');
  const searchParams = await props.searchParams;
  const { initialSidebarCollapsed } = await readDashboardShellState();

  const page = Math.max(1, Number(searchParams.page ?? 1) || 1);
  const status = searchParams.status as SiteResolutionStatus | undefined;
  const siteId = searchParams.siteId?.trim() || undefined;

  let result: Awaited<ReturnType<typeof getSiteResolutionsPage>>;
  try {
    result = await getSiteResolutionsPage({
      page,
      limit: 50,
      ...(status ? { status } : {}),
      ...(siteId ? { siteId } : {}),
    });
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadResolutions' });
    return (
      <AdminShell
        title={tNav('resolutions')}
        activeItem="resolutions"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title={tNav('resolutions')}
      activeItem="resolutions"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <ResolutionsWorkspace initialData={result.data} initialMeta={result.meta} />
    </AdminShell>
  );
}
