'use client';

import Link from 'next/link';
import { Card, Icon } from '@/components/ui';
import styles from './upcoming-cleanups-card.module.css';

type UpcomingEvent = {
  id: string;
  name: string;
  date: string;
};

type UpcomingCleanupsCardProps = {
  upcoming: number;
  completed: number;
  upcomingEvents?: UpcomingEvent[];
};

function formatEventDate(dateStr: string): string {
  const d = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.floor((d.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Tomorrow';
  if (diffDays < 7) return d.toLocaleDateString(undefined, { weekday: 'short' });
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

export function UpcomingCleanupsCard({ upcoming, completed, upcomingEvents = [] }: UpcomingCleanupsCardProps) {
  return (
    <Card padding="md" as="div" className={styles.card}>
      <span className={styles.sectionLabel}>Events</span>
      <div className={styles.header}>
        <span className={styles.iconWrap}>
          <Icon name="calendar" size={18} className={styles.icon} aria-hidden />
        </span>
        <span className={styles.summary}>
          <span className={styles.value}>{upcoming} upcoming</span>
          <span className={styles.sep}>·</span>
          <span className={styles.value}>{completed} completed</span>
        </span>
        <Link href="/dashboard/events" className={styles.viewAll}>
          View all
          <Icon name="chevron-right" size={14} className={styles.chevron} aria-hidden />
        </Link>
      </div>
      <div className={styles.cardBody}>
        {upcomingEvents.length > 0 ? (
          <ul className={styles.eventList}>
            {upcomingEvents.map((e) => (
              <li key={e.id}>
                <Link href="/dashboard/events" className={styles.eventLink}>
                  <span className={styles.eventName}>{e.name}</span>
                  <span className={styles.eventDate}>{formatEventDate(e.date)}</span>
                </Link>
              </li>
            ))}
          </ul>
        ) : null}
      </div>
    </Card>
  );
}
