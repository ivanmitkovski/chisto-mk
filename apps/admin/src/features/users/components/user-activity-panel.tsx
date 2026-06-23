'use client';

import { useTranslations } from 'next-intl';
import { Card, SectionState } from '@/components/ui';
import type { UserActivityDetails } from '@/features/users/data/users-adapter';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './user-activity-panel.module.css';

type UserActivityPanelProps = {
  activity: UserActivityDetails | null;
  loadError?: string | null;
};

export function UserActivityPanel({ activity, loadError = null }: UserActivityPanelProps) {
  const t = useTranslations('users');
  const locale = useAdminBcp47Locale();

  if (loadError) {
    return <SectionState variant="error" message={loadError} />;
  }

  if (!activity) {
    return <p className={styles.empty}>{t('detail.activity.empty')}</p>;
  }

  return (
    <Card padding="md">
      <p className={styles.summary}>
        {t('detail.activity.sessionsToday', { count: activity.sessionsToday })}
      </p>
      <p className={styles.summary}>
        {t('detail.activity.lastActive', {
          value: activity.user.lastActiveAt
            ? formatAdminDateTime(activity.user.lastActiveAt, locale)
            : '—',
        })}
      </p>
      <h3 className={styles.title}>{t('detail.activity.timeline')}</h3>
      {activity.timeline.length === 0 ? (
        <p className={styles.empty}>{t('detail.activity.noEvents')}</p>
      ) : (
        <ul className={styles.timeline}>
          {activity.timeline.map((item) => (
            <li key={item.id}>
              <span className={styles.eventType}>{item.type}</span>
              <span className={styles.eventLabel}>{item.label}</span>
              <span className={styles.eventTime}>
                {formatAdminDateTime(item.occurredAt, locale)}
              </span>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}
