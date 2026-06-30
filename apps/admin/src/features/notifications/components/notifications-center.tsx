'use client';

import { useCallback, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useRouter } from 'next/navigation';
import { Card, Icon, Pagination, SectionState, useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { useNotifications } from '../context/notifications-context';
import { NotificationRelativeTime } from './notification-relative-time';
import { AdminNotification } from '../types';
import styles from './notifications-center.module.css';

type FilterKey = 'all' | 'unread' | 'reports' | 'system' | 'analytics';

type FilterOption = {
  key: FilterKey;
  labelKey: FilterKey;
};

const FILTERS: ReadonlyArray<FilterOption> = [
  { key: 'all', labelKey: 'all' },
  { key: 'unread', labelKey: 'unread' },
  { key: 'reports', labelKey: 'reports' },
  { key: 'system', labelKey: 'system' },
  { key: 'analytics', labelKey: 'analytics' },
];

function toneClassName(tone: AdminNotification['tone']) {
  if (tone === 'success') return styles.iconToneSuccess;
  if (tone === 'warning') return styles.iconToneWarning;
  if (tone === 'info') return styles.iconToneInfo;
  return styles.iconToneNeutral;
}

type NotificationsCenterProps = {
  items: AdminNotification[];
  unreadCount: number;
  total: number;
  page: number;
  limit: number;
  filter: FilterKey;
  onFilterChange: (filter: FilterKey) => void;
  onPageChange: (page: number) => void;
  onRefetch: () => void;
};

export function NotificationsCenter({
  items: initialItems,
  unreadCount,
  total,
  page,
  limit,
  filter,
  onFilterChange,
  onPageChange,
  onRefetch,
}: NotificationsCenterProps) {
  const t = useTranslations('notifications');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const notificationsCtx = useNotifications();
  const { showToast } = useToast();
  const [items, setItems] = useState<AdminNotification[]>(() => initialItems.map((item) => ({ ...item })));

  useEffect(() => {
    setItems(initialItems.map((item) => ({ ...item })));
  }, [initialItems]);

  const markAllRead = useCallback(async () => {
    const previous = items;
    setItems((prev) => prev.map((item) => ({ ...item, isUnread: false })));
    try {
      if (notificationsCtx) {
        await notificationsCtx.markAllRead();
      } else {
        await adminBrowserFetch('/admin/notifications/read-all', { method: 'PATCH' });
      }
      onRefetch();
    } catch {
      setItems(previous);
      showToast({
        tone: 'warning',
        title: tCommon('couldNotMarkRead'),
        message: tCommon('changesRevertedTryAgain'),
      });
    }
  }, [items, notificationsCtx, onRefetch, showToast, tCommon]);

  const markOneRead = useCallback(
    async (id: string) => {
      const previous = items;
      const wasUnread = items.some((item) => item.id === id && item.isUnread);
      setItems((prev) =>
        prev.map((item) =>
          item.id === id && item.isUnread ? { ...item, isUnread: false } : item,
        ),
      );
      try {
        await adminBrowserFetch(`/admin/notifications/${encodeURIComponent(id)}/read`, {
          method: 'PATCH',
        });
        notificationsCtx?.applyNotificationRead(id, wasUnread);
      } catch {
        setItems(previous);
        showToast({
          tone: 'warning',
          title: tCommon('couldNotMarkRead'),
          message: tCommon('changesRevertedTryAgain'),
        });
      }
    },
    [items, notificationsCtx, showToast, tCommon],
  );

  const totalPages = Math.max(1, Math.ceil(total / limit));

  return (
    <div className={styles.root}>
      <header className={styles.header}>
        <div>
          <h2 className={styles.title}>{t('title')}</h2>
          <p className={styles.subtitle}>{t('subtitle', { unread: unreadCount, total })}</p>
        </div>
        <div className={styles.filters} role="toolbar" aria-label={t('filtersAria')}>
          {FILTERS.map((option) => (
            <button
              key={option.key}
              type="button"
              className={`${styles.filterChip} ${filter === option.key ? styles.filterChipActive : ''}`}
              onClick={() => onFilterChange(option.key)}
              aria-pressed={filter === option.key}
            >
              {t(`filters.${option.labelKey}`)}
            </button>
          ))}
        </div>
      </header>

      <Card className={styles.listCard} aria-label={t('listAria')}>
        <div className={styles.listHeader}>
          <h2 className={styles.listTitle}>{t('activity')}</h2>
          <button
            type="button"
            className={styles.markAllButton}
            onClick={() => void markAllRead()}
            disabled={unreadCount === 0}
          >
            {tCommon('markAllAsRead')}
          </button>
        </div>

        {items.length === 0 ? (
          <SectionState
            variant="empty"
            message={filter === 'unread' ? t('emptyUnread') : t('emptyAll')}
          />
        ) : (
          <ul className={styles.items}>
            {items.map((notification) => (
              <li key={notification.id} className={styles.item}>
                <button
                  type="button"
                  className={styles.itemButton}
                  onClick={() => {
                    void markOneRead(notification.id);
                    if (notification.href) {
                      router.push(notification.href);
                    }
                  }}
                >
                  <span className={`${styles.iconWrap} ${toneClassName(notification.tone)}`} aria-hidden>
                    <Icon name={notification.icon} size={16} />
                  </span>
                  <div className={styles.textWrap}>
                    <p className={styles.itemTitle}>{notification.title}</p>
                    <p className={styles.itemMessage}>{notification.message}</p>
                    {notification.messageTemplateKey ? (
                      <p className={styles.templateKey}>{notification.messageTemplateKey}</p>
                    ) : null}
                    {notification.href ? (
                      <span className={styles.link}>{t('viewDetails')}</span>
                    ) : null}
                  </div>
                  <div className={styles.meta}>
                    {notification.isUnread ? (
                      <span className={styles.unreadDot} aria-label={tCommon('unreadDotAria')} />
                    ) : null}
                    <NotificationRelativeTime
                      fallbackLabel={notification.timeLabel}
                      {...(notification.createdAt != null && notification.createdAt !== ''
                        ? { createdAt: notification.createdAt }
                        : {})}
                    />
                  </div>
                </button>
              </li>
            ))}
          </ul>
        )}

        {total > limit ? (
          <div className={styles.pagination}>
            <Pagination totalPages={totalPages} currentPage={page} onPageChange={onPageChange} />
          </div>
        ) : null}
      </Card>
    </div>
  );
}
