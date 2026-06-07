'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { motion, useReducedMotion } from 'framer-motion';
import { Icon } from '@/components/ui';
import type { EventsStats } from '@/features/events/data/events-adapter';
import styles from './events-workspace.module.css';

export function EventsWorkspaceStatsMotion(props: {
  stats: EventsStats;
  totalParticipants: number;
  moderationQueueHref: string;
}) {
  const { stats, totalParticipants, moderationQueueHref } = props;
  const t = useTranslations('events');
  const reduceMotion = useReducedMotion();
  const transition = (delay = 0) =>
    reduceMotion ? { duration: 0 } : { duration: 0.2, delay };

  return (
    <div className={styles.statsBar}>
      <motion.div
        className={styles.statCard}
        initial={{ opacity: 0, y: 4 }}
        animate={{ opacity: 1, y: 0 }}
        transition={transition()}
      >
        <span className={styles.statIcon}>
          <Icon name="calendar" size={18} aria-hidden />
        </span>
        <span className={styles.statValue}>{stats.total}</span>
        <span className={styles.statLabel}>{t('stats.overviewTotal')}</span>
      </motion.div>
      <motion.div
        className={styles.statCard}
        initial={{ opacity: 0, y: 4 }}
        animate={{ opacity: 1, y: 0 }}
        transition={transition(0.05)}
      >
        <span className={styles.statIconUpcoming}>
          <Icon name="document-forward" size={18} aria-hidden />
        </span>
        <span className={styles.statValue}>{stats.upcoming}</span>
        <span className={styles.statLabel}>{t('stats.upcoming')}</span>
      </motion.div>
      <motion.div
        className={styles.statCard}
        initial={{ opacity: 0, y: 4 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.2, delay: 0.1 }}
      >
        <span className={styles.statIconPending}>
          <Icon name="document-text" size={18} aria-hidden />
        </span>
        <span className={styles.statValue}>{stats.pending}</span>
        <span className={styles.statLabel}>{t('stats.pending')}</span>
        {stats.pending > 0 ? (
          <Link className={styles.queueLink} href={moderationQueueHref}>
            {t('stats.openModerationQueue')}
          </Link>
        ) : null}
      </motion.div>
      <motion.div
        className={styles.statCard}
        initial={{ opacity: 0, y: 4 }}
        animate={{ opacity: 1, y: 0 }}
        transition={transition(0.15)}
      >
        <span className={styles.statIconCompleted}>
          <Icon name="check" size={18} aria-hidden />
        </span>
        <span className={styles.statValue}>{stats.completed}</span>
        <span className={styles.statLabel}>{t('stats.completed')}</span>
      </motion.div>
      <motion.div
        className={styles.statCard}
        initial={{ opacity: 0, y: 4 }}
        animate={{ opacity: 1, y: 0 }}
        transition={transition(0.2)}
      >
        <span className={styles.statIconParticipants}>
          <Icon name="users" size={18} aria-hidden />
        </span>
        <span className={styles.statValue}>{totalParticipants}</span>
        <span className={styles.statLabel}>{t('stats.totalParticipants')}</span>
      </motion.div>
    </div>
  );
}
