'use client';

import { useEffect, useRef } from 'react';
import { useLocale, useTranslations } from 'next-intl';
import { formatAdminDateTime } from '@/lib/i18n/format-admin-datetime';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './activity-feed.module.css';

export function ActivityFeedPanel() {
  const t = useTranslations('activeUsers');
  const locale = useLocale();
  const { feed, hasMore, isLoadingMore, loadMore } = useActiveUsersLive();
  const panelRef = useRef<HTMLElement>(null);
  const sentinelRef = useRef<HTMLLIElement>(null);

  useEffect(() => {
    const root = panelRef.current;
    const sentinel = sentinelRef.current;
    if (!root || !sentinel || !hasMore) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          loadMore();
        }
      },
      { root, rootMargin: '48px', threshold: 0 },
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [hasMore, loadMore, feed.length]);

  return (
    <section ref={panelRef} className={styles.panel}>
      <h3 className={styles.title}>{t('activityFeed')}</h3>
      <ul className={styles.list}>
        {feed.length === 0 ? (
          <li className={styles.empty}>{t('noActivity')}</li>
        ) : (
          feed.map((item) => (
            <li key={item.id} className={styles.item}>
              <span className={styles.message}>{item.message}</span>
              <span className={styles.time}>
                {formatAdminDateTime(item.occurredAt, locale, { hour: '2-digit', minute: '2-digit' })}
              </span>
            </li>
          ))
        )}
        {feed.length > 0 && hasMore ? (
          <li ref={sentinelRef} className={styles.footer} aria-hidden />
        ) : null}
        {feed.length > 0 && isLoadingMore ? (
          <li className={styles.footer}>{t('loadingMore')}</li>
        ) : null}
        {feed.length > 0 && !hasMore ? (
          <li className={styles.footerMuted}>{t('feedEnd')}</li>
        ) : null}
      </ul>
      {feed.length > 0 && hasMore ? (
        <button type="button" className={styles.loadMoreBtn} onClick={loadMore} disabled={isLoadingMore}>
          {isLoadingMore ? t('loadingMore') : t('loadMore')}
        </button>
      ) : null}
    </section>
  );
}
