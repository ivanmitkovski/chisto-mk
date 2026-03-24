'use client';

import Link from 'next/link';
import { Card, Icon, SectionState } from '@/components/ui';
import type { IconName } from '@/components/ui';
import type { RecentActivityItem } from '../types';
import { formatRelativeTime } from '../utils/relative-time';
import styles from './recent-activity-feed.module.css';

type RecentActivityFeedProps = {
  items: RecentActivityItem[];
};

function getActionIcon(action: string): IconName {
  if (action.includes('LOGIN')) return 'shield';
  if (action.includes('USER')) return 'user';
  if (action.includes('REPORT')) return 'document-forward';
  if (action.includes('SITE')) return 'location';
  return 'scroll-text';
}

function getActionLink(item: RecentActivityItem): string | null {
  if (item.resourceType === 'User' && item.resourceId) {
    return `/dashboard/users/${item.resourceId}`;
  }
  if (item.resourceType === 'Report' && item.resourceId) {
    return `/dashboard/reports?reportId=${item.resourceId}`;
  }
  return null;
}

function getDayLabel(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffDay = Math.floor((now.getTime() - date.getTime()) / (24 * 60 * 60 * 1000));
  if (diffDay === 0) return 'Today';
  if (diffDay === 1) return 'Yesterday';
  return date.toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' });
}

const DISPLAY_LIMIT = 5;

export function RecentActivityFeed({ items }: RecentActivityFeedProps) {
  if (items.length === 0) {
    return (
      <Card padding="md" className={styles.card}>
        <span className={styles.sectionLabel}>Activity</span>
        <h3 className={styles.title}>Recent Activity</h3>
        <SectionState variant="empty" message="No recent activity yet. Actions will appear here as they occur." />
      </Card>
    );
  }

  const displayItems = items.slice(0, DISPLAY_LIMIT);
  const groups = new Map<string, RecentActivityItem[]>();
  for (const item of displayItems) {
    const label = getDayLabel(item.createdAt);
    const list = groups.get(label) ?? [];
    list.push(item);
    groups.set(label, list);
  }

  return (
    <Card padding="md" className={styles.card} aria-live="polite">
      <span className={styles.sectionLabel}>Activity</span>
      <h3 className={styles.title}>Recent Activity</h3>
      <div className={styles.groups}>
        {Array.from(groups.entries()).map(([dayLabel, dayItems]) => (
          <div key={dayLabel} className={styles.dayGroup}>
            <span className={styles.dayLabel}>{dayLabel}</span>
            <ul className={styles.list}>
              {dayItems.map((item) => {
                const href = getActionLink(item);
                const content = (
                  <span className={styles.content}>
                    <span className={styles.iconWrap}>
                      <Icon name={getActionIcon(item.action)} size={12} />
                    </span>
                    <span className={styles.mainText}>
                      <span className={styles.action}>{item.action.replace(/_/g, ' ')}</span>
                      <span className={styles.meta}>
                        {item.resourceType}
                        {item.resourceId ? ` · ${String(item.resourceId).slice(0, 8)}…` : ''}
                        {item.actorEmail ? ` · by ${item.actorEmail}` : ''}
                      </span>
                    </span>
                    <span className={styles.time}>
                      {formatRelativeTime(item.createdAt)}
                    </span>
                  </span>
                );
                return (
                  <li key={item.id} className={styles.item}>
                    {href ? (
                      <Link href={href} className={styles.link}>
                        {content}
                      </Link>
                    ) : (
                      content
                    )}
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </div>
      <Link href="/dashboard/audit" className={styles.viewAll}>
        <span>View all audit log</span>
        <Icon name="chevron-right" size={14} className={styles.viewAllChevron} />
      </Link>
    </Card>
  );
}
