import { cookies } from 'next/headers';
import { AdminShell, DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getSiteResolutionsPage } from '@/features/sites/data/resolutions-adapter';
import { ResolutionsWorkspace } from '@/features/sites/components/resolutions-workspace';
import type { SiteResolutionStatus } from '@/features/sites/data/resolutions-adapter';

type PageProps = {
  searchParams: Promise<{ page?: string; status?: string; siteId?: string }>;
};

export default async function ResolutionsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['sites:read']);
  const searchParams = await props.searchParams;
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  const page = Math.max(1, Number(searchParams.page ?? 1) || 1);
  const status = searchParams.status as SiteResolutionStatus | undefined;
  const siteId = searchParams.siteId?.trim() || undefined;

  const result = await getSiteResolutionsPage({
    page,
    limit: 50,
    ...(status ? { status } : {}),
    ...(siteId ? { siteId } : {}),
  });

  return (
    <AdminShell title="Resolutions" activeItem="resolutions" initialSidebarCollapsed={initialSidebarCollapsed}>
      <ResolutionsWorkspace initialData={result.data} initialMeta={result.meta} />
    </AdminShell>
  );
}
