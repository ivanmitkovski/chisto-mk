'use client';

import { useTranslations } from 'next-intl';
import type { NewsPostAdminDto } from '../news-api-types';
import { countsByStatus } from '../lib/news-locale-utils';
import styles from './news-stats-bar.module.css';

type NewsStatsBarProps = {
  posts: NewsPostAdminDto[];
  countsByStatusFromApi?: Record<string, number>;
};

export function NewsStatsBar({ posts, countsByStatusFromApi }: NewsStatsBarProps) {
  const t = useTranslations('news');
  const counts = countsByStatusFromApi ?? countsByStatus(posts);

  const items = [
    { key: 'draft', count: counts.draft ?? 0 },
    { key: 'scheduled', count: counts.scheduled ?? 0 },
    { key: 'published', count: counts.published ?? 0 },
    { key: 'archived', count: counts.archived ?? 0 },
  ];

  return (
    <div className={styles.root} role="status" aria-label={t('stats.label')}>
      {items.map(({ key, count }) => (
        <span key={key} className={styles.item}>
          <strong>{count}</strong> {t(`status.${key}` as 'status.draft')}
        </span>
      ))}
    </div>
  );
}
