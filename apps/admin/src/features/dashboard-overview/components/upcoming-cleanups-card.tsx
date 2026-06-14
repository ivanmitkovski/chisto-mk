'use client';

import Link from 'next/link';
import { useLocale, useTranslations } from 'next-intl';
import { Card, Icon } from '@/components/ui';
import { useClientHydrated } from '@/lib/hooks/use-client-hydrated';
import { formatAdminDate } from '@/lib/i18n/format-admin-datetime';
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

export function UpcomingCleanupsCard({ upcoming, completed, upcomingEvents = [] }: UpcomingCleanupsCardProps) {
  const t = useTranslations('dashboard.events');
  const tCommon = useTranslations('common');
  const locale = useLocale();
  const hydrated = useClientHydrated();

  function formatEventDate(dateStr: string): string {
    const d = new Date(dateStr);
    if (!hydrated) {
      return formatAdminDate(dateStr, locale, { month: 'short', day: 'numeric' });
    }
    const now = new Date();
    const diffDays = Math.floor((d.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));
    if (diffDays === 0) return tCommon('today');
    if (diffDays === 1) return tCommon('tomorrow');
    if (diffDays < 7) {
      return formatAdminDate(dateStr, locale, { weekday: 'short' });
    }
    return formatAdminDate(dateStr, locale, { month: 'short', day: 'numeric' });
  }

  return (
    <Card padding="md" as="div" className={styles.card}>
      <span className={styles.sectionLabel}>{t('sectionLabel')}</span>
      <div className={styles.header}>
        <span className={styles.iconWrap}>
          <Icon name="calendar" size={18} className={styles.icon} aria-hidden />
        </span>
        <span className={styles.summary}>
          <span className={styles.value}>{t('upcoming', { count: upcoming })}</span>
          <span className={styles.sep}>·</span>
          <span className={styles.value}>{t('completed', { count: completed })}</span>
        </span>
        <Link href="/dashboard/events" className={styles.viewAll}>
          {t('viewAll')}
          <Icon name="chevron-right" size={14} className={styles.chevron} aria-hidden />
        </Link>
      </div>
      <div className={styles.cardBody}>
        {upcomingEvents.length > 0 ? (
          <ul className={styles.eventList}>
            {upcomingEvents.map((e) => (
              <li key={e.id}>
                <Link href={`/dashboard/events/${e.id}`} className={styles.eventLink}>
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
