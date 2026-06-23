import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { NewsWorkspace, listNewsPosts } from '@/features/news';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export default async function NewsPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['news:read']);
  const t = await getTranslations('news');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  try {
    const posts = await listNewsPosts();
    return (
      <AdminShell title={t('pageTitle')} activeItem="news" initialSidebarCollapsed={initialSidebarCollapsed}>
        <NewsWorkspace initialPosts={posts} />
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
