import { getTranslations } from 'next-intl/server';
import { notFound } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { NewsEditor, getNewsPost } from '@/features/news';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type Props = { params: Promise<{ id: string }> };

export default async function NewsDetailPage({ params }: Props) {
  await requirePagePermission(ADMIN_PERMISSIONS['news:read']);
  const { id } = await params;
  const t = await getTranslations('news');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  try {
    const post = await getNewsPost(id);
    return (
      <AdminShell
        title={post.translations.en.title || post.slug}
        activeItem="news"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <NewsEditor post={post} />
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadNews' });
    if (message.includes('404') || message.toLowerCase().includes('not found')) {
      notFound();
    }
    return (
      <AdminShell title={t('pageTitle')} activeItem="news" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
