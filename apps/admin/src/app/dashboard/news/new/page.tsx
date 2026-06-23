import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { NewsCreatePage } from '@/features/news';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export default async function NewsNewPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['news:write']);
  const t = await getTranslations('news');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  return (
    <AdminShell title={t('create.title')} activeItem="news" initialSidebarCollapsed={initialSidebarCollapsed}>
      <NewsCreatePage />
    </AdminShell>
  );
}
