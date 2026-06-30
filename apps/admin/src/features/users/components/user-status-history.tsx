'use client';

import { useTranslations } from 'next-intl';
import { Card } from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './user-status-history.module.css';

export type UserStatusHistoryEntry = {
  id: string;
  fromStatus: string;
  toStatus: string;
  reasonCode: string;
  note: string | null;
  createdAt: string;
  actorEmail: string;
};

type UserStatusHistoryProps = {
  entries: UserStatusHistoryEntry[];
};

export function UserStatusHistory({ entries }: UserStatusHistoryProps) {
  const t = useTranslations('users');
  const locale = useAdminBcp47Locale();

  return (
    <Card padding="md" className={styles.root}>
      <h3 className={styles.title}>{t('detail.statusHistory.title')}</h3>
      {entries.length === 0 ? (
        <p className={styles.empty}>{t('detail.statusHistory.empty')}</p>
      ) : (
        <ul className={styles.list}>
          {entries.map((entry) => (
            <li key={entry.id}>
              <p className={styles.change}>
                {entry.fromStatus} → {entry.toStatus}
              </p>
              <p className={styles.reason}>
                {t(`detail.suspensionReasons.${entry.reasonCode}`, {
                  default: entry.reasonCode,
                })}
              </p>
              {entry.note ? <p className={styles.note}>{entry.note}</p> : null}
              <p className={styles.meta}>
                {entry.actorEmail} · {formatAdminDateTime(entry.createdAt, locale)}
              </p>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}
