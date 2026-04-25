'use client';

import Link from 'next/link';
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
        <span className={styles.statLabel}>Overview total</span>
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
        <span className={styles.statLabel}>Upcoming</span>
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
        <span className={styles.statLabel}>Pending</span>
        {stats.pending > 0 ? (
          <Link className={styles.queueLink} href={moderationQueueHref}>
            Open moderation queue
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
        <span className={styles.statLabel}>Completed</span>
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
        <span className={styles.statLabel}>Participants (this page)</span>
      </motion.div>
    </div>
  );
}
