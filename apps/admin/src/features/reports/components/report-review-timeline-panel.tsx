'use client';

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
  return (
    <motion.article
      className={styles.panel}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.15 }}
      aria-label="Report timeline"
    >
      <div className={styles.sectionHeader}>
        <h3>Lifecycle timeline</h3>
        <span>{entries.length} events</span>
      </div>
      {entries.length === 0 ? (
        <div className={styles.sectionEmpty}>
          <SectionState
            variant="empty"
            message="Timeline entries will appear as moderation actions are performed."
          />
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
                <span>By {entry.actor}</span>
              </div>
            </li>
          ))}
        </ol>
      )}
    </motion.article>
  );
}
