'use client';

import Link from 'next/link';
import { useLocale, useTranslations } from 'next-intl';
import type { ConflictingEventInfo } from '@/features/events/lib/event-schedule-conflict-client';
import { formatEventAdminDateTime } from '@/features/events/lib/event-admin-datetime';
import styles from './schedule-conflict-banner.module.css';

type ScheduleConflictBannerProps = {
  hint: ConflictingEventInfo | null;
  checking: boolean;
  fetchFailed?: boolean;
  withBottomMargin?: boolean;
  overrideChecked?: boolean;
  onOverrideChange?: (checked: boolean) => void;
  readOnly?: boolean;
};

export function ScheduleConflictBanner({
  hint,
  checking,
  fetchFailed = false,
  withBottomMargin = false,
  overrideChecked = false,
  onOverrideChange,
  readOnly = false,
}: ScheduleConflictBannerProps) {
  const locale = useLocale();
  const t = useTranslations('events');

  const className = withBottomMargin ? styles.bannerWithMargin : styles.banner;

  if (fetchFailed) {
    return (
      <div className={`${className} ${styles.bannerError}`} role="alert">
        {t('scheduleConflict.previewFailed')}
      </div>
    );
  }

  if (checking) {
    return (
      <div className={className} role="status">
        {t('scheduleConflict.checking')}
      </div>
    );
  }

  if (!hint) {
    return null;
  }

  return (
    <div className={className} role="status">
      {t('scheduleConflict.overlapHint', {
        title: hint.title,
        datetime: formatEventAdminDateTime(hint.scheduledAt, locale),
      })}{' '}
      <Link href={`/dashboard/events/${hint.id}`}>{t('scheduleConflict.openEvent')}</Link>.
      {!readOnly && onOverrideChange ? (
        <label className={styles.overrideRow}>
          <input
            type="checkbox"
            checked={overrideChecked}
            onChange={(event) => onOverrideChange(event.target.checked)}
          />
          {t('scheduleConflict.overrideLabel')}
        </label>
      ) : null}
    </div>
  );
}
