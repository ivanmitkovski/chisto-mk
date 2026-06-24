import { getTranslations } from 'next-intl/server';
import { notFound, redirect } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { NewsEditor, getNewsPost } from '@/features/news';
import { canWriteNews } from '@/features/news/lib/news-write-access';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
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
    const [post, me] = await Promise.all([getNewsPost(id), getMeProfile()]);
    return (
      <AdminShell
        title={post.translations.en.title || post.slug}
        activeItem="news"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <NewsEditor post={post} canWriteNews={canWriteNews(me.role)} />
      </AdminShell>
    );
  } catch (error) {
    if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
      redirect('/login');
    }
    if (error instanceof ApiError && (error.code === 'NEWS_POST_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadNews' });
    return (
      <AdminShell title={t('pageTitle')} activeItem="news" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
