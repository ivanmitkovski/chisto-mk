'use client';

import { useEffect, useRef } from 'react';
import Link from 'next/link';
import { useLocale, useTranslations } from 'next-intl';
import { Button, Card, SectionState } from '@/components/ui';
import { formatAdminDateTime } from '@/lib/i18n/format-admin-datetime';
import { ACTIVE_USERS_FEED_TYPE_OPTIONS } from '../constants/active-users-filters';
import { feedTypeLabelKey } from '../lib/feed-type-label';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './activity-feed.module.css';

type ActivityFeedPanelProps = {
  feedType: string;
  onFeedTypeChange: (type: string) => void;
};

const FEED_DOM_CAP = 100;

export function ActivityFeedPanel({ feedType, onFeedTypeChange }: ActivityFeedPanelProps) {
  const t = useTranslations('activeUsers');
  const locale = useLocale();
  const { feed, hasMore, isLoadingMore, loadMore, feedError, refresh, setFeedType } =
    useActiveUsersLive();
  const panelRef = useRef<HTMLDivElement>(null);
  const sentinelRef = useRef<HTMLDivElement>(null);

  const visibleFeed = feed.length > FEED_DOM_CAP ? feed.slice(0, FEED_DOM_CAP) : feed;
  const feedTruncated = feed.length > FEED_DOM_CAP;

  useEffect(() => {
    if (feedType) {
      setFeedType(feedType);
    }
  }, [feedType, setFeedType]);

  useEffect(() => {
    const root = panelRef.current;
    const sentinel = sentinelRef.current;
    if (!root || !sentinel || !hasMore || feedTruncated) return;

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
  }, [hasMore, loadMore, feed.length, feedTruncated]);

  return (
    <Card padding="md" className={styles.panel}>
      <div className={styles.header}>
        <h3 className={styles.title}>{t('activityFeed')}</h3>
        <div className={styles.filters} role="group" aria-label={t('feed.filterLabel')}>
          {ACTIVE_USERS_FEED_TYPE_OPTIONS.map((opt) => (
            <button
              key={opt.value || 'all'}
              type="button"
              className={feedType === opt.value ? styles.filterActive : styles.filter}
              onClick={() => onFeedTypeChange(opt.value)}
            >
              {t(opt.labelKey)}
            </button>
          ))}
        </div>
      </div>

      {feedError ? (
        <SectionState variant="error" message={t('errors.feedFailed')}>
          <Button type="button" variant="outline" size="sm" onClick={() => refresh()}>
            {t('retry')}
          </Button>
        </SectionState>
      ) : (
        <div ref={panelRef} className={styles.listWrap}>
          <ul className={styles.list}>
            {visibleFeed.length === 0 ? (
              <li className={styles.empty}>{t('noActivity')}</li>
            ) : (
              visibleFeed.map((item) => (
                <li key={item.id} className={styles.item}>
                  <div className={styles.itemTop}>
                    <Link href={`/dashboard/users/${item.userId}`} className={styles.name}>
                      {item.displayName}
                    </Link>
                    <span className={styles.typePill}>{t(feedTypeLabelKey(item.type))}</span>
                  </div>
                  <p className={styles.message}>{item.message}</p>
                  {item.screen ? (
                    <p className={styles.screen}>
                      {t('screenLabel')}: {item.screen}
                    </p>
                  ) : null}
                  <span className={styles.time}>
                    {formatAdminDateTime(item.occurredAt, locale, {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </span>
                </li>
              ))
            )}
            {feedTruncated ? (
              <li className={styles.footerMuted}>{t('feedDomCap', { count: FEED_DOM_CAP })}</li>
            ) : null}
            {visibleFeed.length > 0 && hasMore && !feedTruncated ? (
              <div ref={sentinelRef} className={styles.sentinel} aria-hidden />
            ) : null}
            {visibleFeed.length > 0 && isLoadingMore ? (
              <li className={styles.footer}>{t('loadingMore')}</li>
            ) : null}
            {visibleFeed.length > 0 && !hasMore ? (
              <li className={styles.footerMuted}>{t('feedEnd')}</li>
            ) : null}
          </ul>
        </div>
      )}

      {visibleFeed.length > 0 && hasMore && !feedTruncated ? (
        <Button
          type="button"
          variant="outline"
          size="sm"
          className={styles.loadMoreBtn}
          onClick={loadMore}
          disabled={isLoadingMore}
        >
          {isLoadingMore ? t('loadingMore') : t('loadMore')}
        </Button>
      ) : null}
    </Card>
  );
}
