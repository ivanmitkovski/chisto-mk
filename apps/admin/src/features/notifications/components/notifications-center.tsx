'use client';

import { useMemo, useState } from 'react';
import { Card, Icon, SectionState } from '@/components/ui';
import { notificationsMock } from '../data';
import { AdminNotification } from '../types';
import styles from './notifications-center.module.css';

type FilterKey = 'all' | 'unread' | 'reports' | 'system' | 'analytics';

type FilterOption = {
  key: FilterKey;
  label: string;
};

const FILTERS: ReadonlyArray<FilterOption> = [
  { key: 'all', label: 'All' },
  { key: 'unread', label: 'Unread' },
  { key: 'reports', label: 'Reports' },
  { key: 'system', label: 'System' },
  { key: 'analytics', label: 'Analytics' },
];

function toneClassName(tone: AdminNotification['tone']) {
  if (tone === 'success') return styles.iconToneSuccess;
  if (tone === 'warning') return styles.iconToneWarning;
  if (tone === 'info') return styles.iconToneInfo;
  return styles.iconToneNeutral;
}

export function NotificationsCenter() {
  const [filter, setFilter] = useState<FilterKey>('all');
  const [items, setItems] = useState(() => notificationsMock.map((item) => ({ ...item })));

  const { filtered, unreadCount } = useMemo(() => {
    const unread = items.filter((item) => item.isUnread).length;

    const filteredItems = items.filter((item) => {
      if (filter === 'all') return true;
      if (filter === 'unread') return item.isUnread;
      return item.category === filter;
    });

    return { filtered: filteredItems, unreadCount: unread };
  }, [filter, items]);

  function markAllRead() {
    setItems((previous) => previous.map((item) => ({ ...item, isUnread: false })));
  }

  return (
    <div className={styles.root}>
      <header className={styles.header}>
        <div>
          <h1 className={styles.title}>Notifications</h1>
          <p className={styles.subtitle}>
            {unreadCount} unread • {items.length} total
          </p>
        </div>
        <div className={styles.filters} role="toolbar" aria-label="Notification filters">
          {FILTERS.map((option) => (
            <button
              key={option.key}
              type="button"
              className={`${styles.filterChip} ${filter === option.key ? styles.filterChipActive : ''}`}
              onClick={() => setFilter(option.key)}
              aria-pressed={filter === option.key}
            >
              {option.label}
            </button>
          ))}
        </div>
      </header>

      <Card className={styles.listCard} aria-label="Notifications list">
        <div className={styles.listHeader}>
          <h2 className={styles.listTitle}>Activity</h2>
          <button
            type="button"
            className={styles.markAllButton}
            onClick={markAllRead}
            disabled={unreadCount === 0}
          >
            Mark all as read
          </button>
        </div>

        {filtered.length === 0 ? (
          <SectionState
            variant="empty"
            message={filter === 'unread' ? 'You are all caught up.' : 'No notifications in this view yet.'}
          />
        ) : (
          <ul className={styles.items}>
            {filtered.map((notification) => (
              <li key={notification.id} className={styles.item}>
                <span className={`${styles.iconWrap} ${toneClassName(notification.tone)}`} aria-hidden>
                  <Icon name={notification.icon} size={16} />
                </span>
                <div className={styles.textWrap}>
                  <p className={styles.itemTitle}>{notification.title}</p>
                  <p className={styles.itemMessage}>{notification.message}</p>
                  {notification.href ? (
                    <a className={styles.link} href={notification.href}>
                      View details
                    </a>
                  ) : null}
                </div>
                <div className={styles.meta}>
                  {notification.isUnread ? <span className={styles.unreadDot} aria-label="Unread" /> : null}
                  <span>{notification.timeLabel}</span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </div>
  );
}
