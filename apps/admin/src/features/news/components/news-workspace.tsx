'use client';

import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useCallback, useMemo, useState } from 'react';
import { Button, Card, PageHeader, Pagination, useToast } from '@/components/ui';
import { WorkspaceRefreshOverlay } from '@/features/admin-shell/components/workspace-refresh-overlay';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { Can } from '@/lib/auth/rbac';
import { NEWS_LIST_PAGE_SIZE } from '../config/news-list-filters';
import { duplicateNewsPost, listNewsPostsClient } from '../data/news-adapter-client';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import { useNewsListUrl } from '../hooks/use-news-list-url';
import { NewsListEmpty } from './news-list-empty';
import { NewsListTable } from './news-list-table';
import { NewsListToolbar } from './news-list-toolbar';
import { NewsStatsCards } from './news-stats-cards';
import styles from './news-workspace.module.css';

type NewsWorkspaceProps = {
  initialData: {
    items: import('../news-api-types').NewsPostAdminDto[];
    total: number;
    countsByStatus: Record<string, number>;
  };
  canWriteNews: boolean;
};

export function NewsWorkspace({ initialData, canWriteNews }: NewsWorkspaceProps) {
  const t = useTranslations('news');
  const router = useRouter();
  const { showToast } = useToast();
  const url = useNewsListUrl();
  const { refresh: refreshPage, isRefreshing } = useWorkspaceRefresh();
  const [data, setData] = useServerSyncedState({
    items: initialData.items ?? [],
    total: initialData.total ?? 0,
    countsByStatus: initialData.countsByStatus ?? {},
  });
  const [loading, setLoading] = useState(false);
  const [duplicatingId, setDuplicatingId] = useState<string | null>(null);

  const totalPosts = useMemo(
    () =>
      Object.values(data.countsByStatus).reduce((sum, count) => sum + (count ?? 0), 0),
    [data.countsByStatus],
  );

  const handleDuplicate = useCallback(
    async (id: string) => {
      setDuplicatingId(id);
      try {
        const copy = await duplicateNewsPost(id);
        showToast({
          tone: 'success',
          title: t('toast.duplicated'),
          message: t('toast.duplicatedMediaHint'),
        });
        router.push(`/dashboard/news/${copy.id}`);
      } catch (error) {
        showToast({
          tone: 'error',
          title: t('toast.error'),
          message: newsApiErrorMessage(error, t, t('toast.error')),
        });
      } finally {
        setDuplicatingId(null);
      }
    },
    [router, showToast, t],
  );

  const refreshList = useCallback(async () => {
    setLoading(true);
    try {
      const result = await listNewsPostsClient({
        page: url.page,
        sort: url.sort,
        ...(url.status ? { status: url.status } : {}),
        ...(url.category ? { category: url.category } : {}),
        ...(url.listQuery ? { q: url.listQuery } : {}),
      });
      setData({
        items: result.items,
        total: result.total,
        countsByStatus: result.countsByStatus,
      });
    } catch (error) {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: newsApiErrorMessage(error, t, t('toast.error')),
      });
    } finally {
      setLoading(false);
    }
  }, [showToast, t, url.category, url.listQuery, url.page, url.sort, url.status]);

  const handleRefresh = () => {
    refreshPage();
    url.refresh();
    void refreshList();
  };

  const totalPages = Math.max(1, Math.ceil(data.total / NEWS_LIST_PAGE_SIZE));
  const showEmpty = !loading && data.items.length === 0;

  return (
    <WorkspaceRefreshOverlay isRefreshing={isRefreshing}>
      <div className={styles.layout}>
        <PageHeader
          className={styles.pageHeader}
          title={t('pageTitle')}
          description={t('pageDescription')}
          actions={
            <Can permission="news:write">
              <Button onClick={() => router.push('/dashboard/news/new')}>{t('actions.new')}</Button>
            </Can>
          }
        />

        {!canWriteNews ? (
          <p className={styles.readOnlyHint} role="note">
            {t('readOnlyHint')}
          </p>
        ) : null}

        <NewsStatsCards
          countsByStatus={data.countsByStatus}
          activeStatus={url.status}
          onStatusSelect={url.handleStatusChange}
        />

        <Card className={styles.tableCard}>
          <NewsListToolbar
            status={url.status}
            category={url.category}
            sort={url.sort}
            searchDraft={url.searchDraft}
            hasActiveFilters={url.hasActiveFilters}
            isRefreshing={isRefreshing || loading}
            onSearchDraftChange={url.setSearchDraft}
            onStatusChange={url.handleStatusChange}
            onCategoryChange={url.handleCategoryChange}
            onSortChange={(v) => url.handleSortChange(v as typeof url.sort)}
            onClearSearch={url.clearSearch}
            onClearAllFilters={url.clearAllFilters}
            onRefresh={handleRefresh}
          />

          <div className={styles.tableCardMain}>
            {showEmpty ? (
              <NewsListEmpty
                totalPosts={totalPosts}
                hasActiveFilters={url.hasActiveFilters}
                searchQuery={url.listQuery}
                onClearFilters={url.clearAllFilters}
              />
            ) : (
              <NewsListTable
                data={data.items}
                canWriteNews={canWriteNews}
                duplicatingId={duplicatingId}
                isLoading={loading}
                onDuplicate={(id) => void handleDuplicate(id)}
              />
            )}
          </div>

          <div className={styles.footer}>
            <p className={styles.meta}>
              {t('table.postsCount', { count: data.total, page: url.page })}
            </p>
            {data.total > NEWS_LIST_PAGE_SIZE ? (
              <Pagination
                currentPage={url.page}
                totalPages={totalPages}
                onPageChange={url.goToPage}
              />
            ) : null}
          </div>
        </Card>
      </div>
    </WorkspaceRefreshOverlay>
  );
}
