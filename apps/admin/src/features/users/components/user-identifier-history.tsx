'use client';

import { useTranslations } from 'next-intl';
import type { AuditEntry } from '@/features/users/data/users-adapter';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import { formatUserAuditAction } from '@/features/users/lib/format-user-audit-action';
import styles from './user-identifier-history.module.css';

type UserIdentifierHistoryProps = {
  entries: AuditEntry[];
};

export function UserIdentifierHistory({ entries }: UserIdentifierHistoryProps) {
  const t = useTranslations('users');
  const locale = useAdminBcp47Locale();

  if (entries.length === 0) {
    return null;
  }

  return (
    <section className={styles.root}>
      <h3 className={styles.title}>{t('detail.identifierHistory.title')}</h3>
      <ul className={styles.list}>
        {entries.map((entry) => (
          <li key={entry.id} className={styles.item}>
            <span className={styles.action}>
              {formatUserAuditAction(entry, {
                identifierChanged: ({ field, initiatedBy }) =>
                  t('detail.identifierHistory.entry', {
                    field: t(`detail.identifierHistory.fields.${field}`),
                    initiatedBy: t(`detail.identifierHistory.initiatedBy.${initiatedBy}`),
                  }),
                defaultAction: (action) => action,
              })}
            </span>
            <span className={styles.meta}>
              {formatAdminDateTime(entry.createdAt, locale)}
              {entry.actorEmail ? ` · ${entry.actorEmail}` : ''}
            </span>
          </li>
        ))}
      </ul>
    </section>
  );
}
