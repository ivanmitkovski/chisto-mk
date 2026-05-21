'use client';

import { useCallback, useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { SectionState } from '@/components/ui';
import {
  fetchSiteHistory,
  type SiteHistoryEntryRow,
} from '@/lib/api/site-history';
import { formatDateTime } from '@/features/reports/utils/report-display';
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
  const [entries, setEntries] = useState<SiteHistoryEntryRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetchSiteHistory(siteId, { limit: 50 });
      setEntries(res.items);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load timeline');
    } finally {
      setLoading(false);
    }
  }, [siteId]);

  useEffect(() => {
    void load();
  }, [load, refreshToken]);

  return (
    <motion.article
      className={styles.panel}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.15 }}
      aria-label="Site timeline"
    >
      <div className={styles.sectionHeader}>
        <h3>Site timeline</h3>
        <span>{entries.length} events</span>
      </div>
      {loading ? (
        <div className={styles.sectionEmpty}>
          <SectionState variant="loading" message="Loading timeline…" />
        </div>
      ) : error ? (
        <div className={styles.sectionEmpty}>
          <SectionState variant="error" message={error} />
        </div>
      ) : entries.length === 0 ? (
        <div className={styles.sectionEmpty}>
          <SectionState
            variant="empty"
            message="Timeline entries will appear as reports, events, and status changes occur."
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
                  <span>By {entry.actor.displayName}</span>
                ) : null}
              </div>
            </li>
          ))}
        </ol>
      )}
    </motion.article>
  );
}
