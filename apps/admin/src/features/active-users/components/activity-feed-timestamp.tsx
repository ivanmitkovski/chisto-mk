'use client';

import { useLocale, useTranslations } from 'next-intl';
import { formatAdminActivityTimestamp } from '@/lib/i18n/format-admin-datetime';
import styles from './activity-feed.module.css';

type ActivityFeedTimestampProps = {
  occurredAt: string;
};

export function ActivityFeedTimestamp({ occurredAt }: ActivityFeedTimestampProps) {
  const locale = useLocale();
  const tCommon = useTranslations('common');
  const label = formatAdminActivityTimestamp(occurredAt, locale, {
    today: tCommon('today'),
    yesterday: tCommon('yesterday'),
  });

  return (
    <time className={styles.time} dateTime={occurredAt}>
      {label}
    </time>
  );
}
