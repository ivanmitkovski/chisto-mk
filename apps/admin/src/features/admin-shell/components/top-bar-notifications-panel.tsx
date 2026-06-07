'use client';

import { RefObject } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Button, Icon } from '@/components/ui';
import { NotificationRelativeTime } from '@/features/notifications/components/notification-relative-time';
import type { TopBarNotification } from '../types/top-bar';
import barStyles from './top-bar.module.css';
import styles from './top-bar-notifications-panel.module.css';

type TopBarNotificationsPanelProps = {
  isOpen: boolean;
  isBellJingling: boolean;
  unreadNotificationsCount: number;
  notifications: TopBarNotification[];
  notifyButtonRef: RefObject<HTMLButtonElement | null>;
  notificationsPanelRef: RefObject<HTMLDivElement | null>;
  onToggle: () => void;
  onMarkAllRead: () => void;
  onMarkRead: (id: string) => void;
  onClose: () => void;
};

export function TopBarNotificationsPanel({
  isOpen,
  isBellJingling,
  unreadNotificationsCount,
  notifications,
  notifyButtonRef,
  notificationsPanelRef,
  onToggle,
  onMarkAllRead,
  onMarkRead,
  onClose,
}: TopBarNotificationsPanelProps) {
  const router = useRouter();
  const t = useTranslations('common');
  const reduceMotion = useReducedMotion();

  return (
    <motion.span className={barStyles.notifyWrap} {...(!reduceMotion ? { whileHover: { y: -1 } } : {})}>
      <Button
        ref={notifyButtonRef}
        variant="icon"
        aria-label={
          unreadNotificationsCount > 0
            ? t('notificationsWithUnreadCount', { count: unreadNotificationsCount })
            : t('notifications')
        }
        aria-expanded={isOpen}
        aria-haspopup="dialog"
        className={`${barStyles.iconButton} ${isOpen ? barStyles.iconButtonOpen : ''} ${isBellJingling ? barStyles.iconButtonJiggle : ''}`}
        onClick={onToggle}
      >
        <Icon name="notification-bing" size={16} />
      </Button>
      {unreadNotificationsCount > 0 ? <span className={barStyles.notifyDot} aria-hidden /> : null}

      <AnimatePresence>
        {isOpen ? (
          <motion.section
            ref={notificationsPanelRef}
            className={styles.dropdownPanel}
            role="dialog"
            aria-label={t('notificationsPanel')}
            initial={reduceMotion ? false : { opacity: 0, y: -6, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
            transition={{ duration: reduceMotion ? 0 : 0.16 }}
          >
            <header className={styles.panelHeader}>
              <div>
                <h2 className={styles.panelTitle}>{t('notifications')}</h2>
                <p className={styles.panelSubtitle}>{t('unreadCount', { count: unreadNotificationsCount })}</p>
              </div>
              <button type="button" className={styles.panelAction} disabled={unreadNotificationsCount === 0} onClick={onMarkAllRead}>
                {t('markAllRead')}
              </button>
            </header>
            <div className={styles.notificationListScroll} role="region" aria-label={t('notificationList')}>
              <ul className={styles.notificationList}>
                {notifications.map((notification) => (
                  <li key={notification.id}>
                    <button
                      type="button"
                      className={`${styles.notificationItem} ${notification.isUnread ? styles.notificationUnread : ''}`}
                      onClick={() => {
                        void onMarkRead(notification.id);
                        if (notification.href) {
                          onClose();
                          router.push(notification.href);
                        }
                      }}
                    >
                      <span className={styles.notificationHeading}>
                        {notification.title}
                        {notification.isUnread ? <span className={styles.unreadPill}>{t('new')}</span> : null}
                      </span>
                      <span className={styles.notificationMessage}>{notification.message}</span>
                      <NotificationRelativeTime
                        fallbackLabel={notification.timeLabel}
                        className={styles.notificationTime}
                        {...(notification.createdAt != null && notification.createdAt !== ''
                          ? { createdAt: notification.createdAt }
                          : {})}
                      />
                    </button>
                  </li>
                ))}
              </ul>
            </div>
            <div className={styles.notificationFooter}>
              <button
                type="button"
                className={styles.notificationLink}
                onClick={() => {
                  onClose();
                  router.push('/dashboard/notifications');
                }}
              >
                {t('viewAllNotifications')}
              </button>
            </div>
          </motion.section>
        ) : null}
      </AnimatePresence>
    </motion.span>
  );
}
