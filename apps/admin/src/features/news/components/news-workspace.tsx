'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useCallback, useState } from 'react';
import { Button, Card, DataTable, PageHeader, Pagination, useToast } from '@/components/ui';
import { WorkspaceRefreshOverlay } from '@/features/admin-shell/components/workspace-refresh-overlay';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { Can } from '@/lib/auth/rbac';
import { NEWS_LIST_PAGE_SIZE } from '../config/news-list-filters';
import { duplicateNewsPost, listNewsPostsClient } from '../data/news-adapter-client';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import { useNewsListUrl } from '../hooks/use-news-list-url';
import type { NewsPostAdminDto } from '../news-api-types';
import { NewsListToolbar } from './news-list-toolbar';
import { NewsStatsBar } from './news-stats-bar';
import { NEWS_LOCALES } from '../types';
import styles from './news-workspace.module.css';

type NewsWorkspaceProps = {
  initialData: {
    items: NewsPostAdminDto[];
    total: number;
    countsByStatus: Record<string, number>;
  };
  canWriteNews: boolean;
};

function statusClass(status: string): string {
  switch (status) {
    case 'published':
      return styles.statusPublished;
    case 'scheduled':
      return styles.statusScheduled;
    case 'archived':
      return styles.statusArchived;
    default:
      return styles.statusDraft;
  }
}

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

  const handleDuplicate = useCallback(
    async (id: string) => {
      setDuplicatingId(id);
      try {
        const copy = await duplicateNewsPost(id);
        showToast({ tone: 'success', title: t('toast.duplicated'), message: '' });
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

  const columns = [
    {
      key: 'title',
      header: t('table.title'),
      render: (row: NewsPostAdminDto) => (
        <div className={styles.titleCell}>
          {row.coverImageUrl ? (
            <div className={styles.thumb}>
              <Image src={row.coverImageUrl} alt="" fill className={styles.thumbImage} unoptimized />
            </div>
          ) : null}
          <div>
            <span className={styles.titleText}>{row.translations.en.title || row.slug}</span>
            {row.featured ? <span className={styles.featuredBadge}>{t('table.featured')}</span> : null}
            <div className={styles.localeChips} aria-label={t('table.locales')}>
              {NEWS_LOCALES.map((loc) => (
                <span
                  key={loc}
                  className={
                    row.localeCompleteness?.[loc] ? styles.chipComplete : styles.chipIncomplete
                  }
                >
                  {loc.toUpperCase()}
                </span>
              ))}
            </div>
          </div>
        </div>
      ),
    },
    {
      key: 'status',
      header: t('table.status'),
      render: (row: NewsPostAdminDto) => (
        <span className={`${styles.statusBadge} ${statusClass(row.status)}`}>
          {t(`status.${row.status}`)}
        </span>
      ),
    },
    {
      key: 'category',
      header: t('table.category'),
      render: (row: NewsPostAdminDto) => t(`category.${row.category}`),
    },
    {
      key: 'publishedAt',
      header: t('table.published'),
      render: (row: NewsPostAdminDto) => {
        if (row.status === 'scheduled' && row.scheduledAt) {
          return t('table.scheduledFor', { date: new Date(row.scheduledAt).toLocaleString() });
        }
        return row.publishedAt ? new Date(row.publishedAt).toLocaleDateString() : '—';
      },
    },
    {
      key: 'actions',
      header: '',
      render: (row: NewsPostAdminDto) => (
        <div className={styles.actionsCell}>
          <Link href={`/dashboard/news/${row.id}`} className={styles.editLink}>
            {canWriteNews ? t('table.edit') : t('table.view')}
          </Link>
          {canWriteNews ? (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={duplicatingId === row.id}
              onClick={() => void handleDuplicate(row.id)}
            >
              {t('actions.duplicate')}
            </Button>
          ) : null}
        </div>
      ),
    },
  ];

  const totalPages = Math.max(1, Math.ceil(data.total / NEWS_LIST_PAGE_SIZE));

  return (
    <WorkspaceRefreshOverlay isRefreshing={isRefreshing}>
    <div className={styles.root}>
      <PageHeader
        title={t('pageTitle')}
        description={t('pageDescription')}
        actions={
          <Can permission="news:write">
            <Button onClick={() => router.push('/dashboard/news/new')}>{t('actions.new')}</Button>
          </Can>
        }
      />
      <NewsStatsBar posts={data.items} countsByStatusFromApi={data.countsByStatus} />
      <NewsListToolbar
        status={url.status}
        category={url.category}
        sort={url.sort}
        searchDraft={url.searchDraft}
        onSearchDraftChange={url.setSearchDraft}
        onStatusChange={url.handleStatusChange}
        onCategoryChange={url.handleCategoryChange}
        onSortChange={(v) => url.handleSortChange(v as typeof url.sort)}
        onSearchApply={url.applySearchToUrl}
        onRefresh={handleRefresh}
      />
      <Card padding="md">
        <DataTable
          columns={columns}
          data={data.items}
          getRowId={(row) => row.id}
          emptyMessage={t('table.empty')}
          isLoading={loading}
        />
        {data.total > NEWS_LIST_PAGE_SIZE ? (
          <Pagination
            currentPage={url.page}
            totalPages={totalPages}
            onPageChange={url.goToPage}
          />
        ) : null}
      </Card>
    </div>
    </WorkspaceRefreshOverlay>
  );
}
