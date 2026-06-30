'use client';

import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, EmptyState } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import styles from './news-workspace.module.css';

type NewsListEmptyProps = {
  totalPosts: number;
  hasActiveFilters: boolean;
  searchQuery: string;
  onClearFilters: () => void;
};

export function NewsListEmpty({
  totalPosts,
  hasActiveFilters,
  searchQuery,
  onClearFilters,
}: NewsListEmptyProps) {
  const t = useTranslations('news');
  const router = useRouter();

  if (totalPosts === 0) {
    return (
      <EmptyState
        className={styles.listEmpty}
        icon="newspaper"
        title={t('empty.noPostsTitle')}
        description={t('empty.noPostsDescription')}
        action={
          <Can permission="news:write">
            <Button type="button" onClick={() => router.push('/dashboard/news/new')}>
              {t('actions.new')}
            </Button>
          </Can>
        }
      />
    );
  }

  if (searchQuery.trim()) {
    return (
      <EmptyState
        className={styles.listEmpty}
        icon="magnifying-glass"
        title={t('empty.noSearchTitle')}
        description={t('empty.noSearchDescription', { query: searchQuery.trim() })}
        action={
          <Button type="button" variant="outline" onClick={onClearFilters}>
            {t('empty.clearFilters')}
          </Button>
        }
      />
    );
  }

  if (hasActiveFilters) {
    return (
      <EmptyState
        className={styles.listEmpty}
        icon="document-text"
        title={t('empty.noFilterTitle')}
        description={t('empty.noFilterDescription')}
        action={
          <Button type="button" variant="outline" onClick={onClearFilters}>
            {t('empty.clearFilters')}
          </Button>
        }
      />
    );
  }

  return (
    <EmptyState
      className={styles.listEmpty}
      icon="document-text"
      title={t('table.empty')}
    />
  );
}
