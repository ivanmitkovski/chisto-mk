'use client';

import { useCallback, useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { SectionState, PanelSkeleton } from '@/components/ui';
import {
  fetchSiteHistory,
  type SiteHistoryEntryRow,
} from '@/lib/api';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from '@/features/reports/components/report-review-card.module.css';

function timelineToneClassName(kind: string): string {
  if (kind.includes('APPROVED') || kind.includes('COMPLETED') || kind === 'UNARCHIVED_BY_ADMIN') {
    return styles.timelineToneSuccess;
  }
  if (kind.includes('REJECTED') || kind.includes('CANCELLED') || kind === 'ARCHIVED_BY_ADMIN') {
    return styles.timelineToneWarning;
  }
  if (kind.includes('STATUS') || kind.includes('EVENT') || kind === 'ADMIN_NOTE') {
    return styles.timelineToneInfo;
  }
  return styles.timelineToneNeutral;
}

function formatKindTitle(entry: SiteHistoryEntryRow): string {
  const base = entry.kind.replace(/_/g, ' ').toLowerCase();
  const titled = base.replace(/\b\w/g, (c) => c.toUpperCase());
  if (entry.fromStatus && entry.toStatus) {
    return `${titled}: ${entry.fromStatus} → ${entry.toStatus}`;
  }
  return titled;
}

type SiteTimelinePanelProps = {
  siteId: string;
  refreshToken?: number;
};

export function SiteTimelinePanel({ siteId, refreshToken = 0 }: SiteTimelinePanelProps) {
  const t = useTranslations('sites');
  const locale = useAdminBcp47Locale();
  const [entries, setEntries] = useState<SiteHistoryEntryRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const formatDateTime = (value: string) => formatAdminDateTime(value, locale);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetchSiteHistory(siteId, { limit: 50 });
      setEntries(res.items);
    } catch (e) {
      setError(e instanceof Error ? e.message : t('detail.timelineLoadFailed'));
    } finally {
      setLoading(false);
    }
  }, [siteId, t]);

  useEffect(() => {
    void load();
  }, [load, refreshToken]);

  return (
    <motion.article
      className={styles.panel}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.15 }}
      aria-label={t('detail.timelineTitle')}
    >
      <div className={styles.sectionHeader}>
        <h3>{t('detail.timelineTitle')}</h3>
        <span>{t('detail.timelineEvents', { count: entries.length })}</span>
      </div>
      {loading ? (
        <PanelSkeleton variant="list" listItems={4} />
      ) : error ? (
        <div className={styles.sectionEmpty}>
          <SectionState variant="error" message={error} />
        </div>
      ) : entries.length === 0 ? (
        <div className={styles.sectionEmpty}>
          <SectionState
            variant="empty"
            message={t('detail.timelineEmpty')}
          />
        </div>
      ) : (
        <ol className={styles.timeline}>
          {entries.map((entry) => (
            <li key={entry.id} className={styles.timelineItem}>
              <span
                className={`${styles.timelineDot} ${timelineToneClassName(entry.kind)}`}
                aria-hidden
              />
              <div className={styles.timelineBody}>
                <div className={styles.timelineHeading}>
                  <strong>{formatKindTitle(entry)}</strong>
                  <time>{formatDateTime(entry.occurredAt)}</time>
                </div>
                {entry.note ? <p>{entry.note}</p> : null}
                {entry.actor?.displayName ? (
                  <span>{t('detail.timelineBy', { name: entry.actor.displayName })}</span>
                ) : null}
              </div>
            </li>
          ))}
        </ol>
      )}
    </motion.article>
  );
}
