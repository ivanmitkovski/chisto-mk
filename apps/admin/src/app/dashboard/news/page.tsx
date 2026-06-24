import { Suspense } from 'react';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { NewsWorkspace, listNewsPosts } from '@/features/news';
import { ListWorkspaceSkeleton } from '@/components/ui';
import { canWriteNews } from '@/features/news/lib/news-write-access';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type Props = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export default async function NewsPage({ searchParams }: Props) {
  await requirePagePermission(ADMIN_PERMISSIONS['news:read']);
  const sp = await searchParams;
  const t = await getTranslations('news');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const page = Math.max(1, Number.parseInt(String(sp.page ?? '1'), 10) || 1);
  const status = typeof sp.status === 'string' ? sp.status : undefined;
  const category = typeof sp.category === 'string' ? sp.category : undefined;
  const q = typeof sp.q === 'string' ? sp.q : undefined;
  const sort = typeof sp.sort === 'string' ? (sp.sort as 'publishedAt' | 'updatedAt' | 'title') : undefined;

  try {
    const [listResult, me] = await Promise.all([
      listNewsPosts({
        page,
        ...(status ? { status } : {}),
        ...(category ? { category } : {}),
        ...(q ? { q } : {}),
        ...(sort ? { sort } : {}),
      }),
      getMeProfile(),
    ]);
    return (
      <AdminShell title={t('pageTitle')} activeItem="news" initialSidebarCollapsed={initialSidebarCollapsed}>
        <Suspense fallback={<ListWorkspaceSkeleton />}>
          <NewsWorkspace
            initialData={{
              items: listResult.items,
              total: listResult.total,
              countsByStatus: listResult.countsByStatus,
            }}
            canWriteNews={canWriteNews(me.role)}
          />
        </Suspense>
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadNews' });
    return (
      <AdminShell title={t('pageTitle')} activeItem="news" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
