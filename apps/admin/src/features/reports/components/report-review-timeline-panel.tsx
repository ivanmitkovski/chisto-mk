'use client';

import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { SectionState } from '@/components/ui';
import type { ReportTimelineEntry } from '../types';
import { formatDateTime } from '../utils/report-display';
import styles from './report-review-card.module.css';

function timelineToneClassName(tone: ReportTimelineEntry['tone']) {
  const classByTone: Record<ReportTimelineEntry['tone'], string> = {
    neutral: styles.timelineToneNeutral,
    info: styles.timelineToneInfo,
    success: styles.timelineToneSuccess,
    warning: styles.timelineToneWarning,
  };

  return classByTone[tone];
}

type ReportReviewTimelinePanelProps = {
  entries: ReportTimelineEntry[];
};

export function ReportReviewTimelinePanel({ entries }: ReportReviewTimelinePanelProps) {
  const t = useTranslations('reports.timeline');

  return (
    <motion.article
      className={styles.panel}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.15 }}
      aria-label={t('ariaLabel')}
    >
      <div className={styles.sectionHeader}>
        <h3>{t('sectionTitle')}</h3>
        <span>{t('eventsCount', { count: entries.length })}</span>
      </div>
      {entries.length === 0 ? (
        <div className={styles.sectionEmpty}>
          <SectionState variant="empty" message={t('empty')} />
        </div>
      ) : (
        <ol className={styles.timeline}>
          {entries.map((entry) => (
            <li key={entry.id} className={styles.timelineItem}>
              <span
                className={`${styles.timelineDot} ${timelineToneClassName(entry.tone)}`}
                aria-hidden
              />
              <div className={styles.timelineBody}>
                <div className={styles.timelineHeading}>
                  <strong>{entry.title}</strong>
                  <time>{formatDateTime(entry.occurredAt)}</time>
                </div>
                <p>{entry.detail}</p>
                <span>{t('byActor', { actor: entry.actor })}</span>
              </div>
            </li>
          ))}
        </ol>
      )}
    </motion.article>
  );
}
