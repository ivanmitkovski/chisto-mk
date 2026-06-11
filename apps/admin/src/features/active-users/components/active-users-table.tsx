'use client';

import { useTranslations } from 'next-intl';
import type { ActiveUserRow } from '../data/active-users.types';
import styles from './active-users-table.module.css';

export function ActiveUsersTable({ rows }: { rows: ActiveUserRow[] }) {
  const t = useTranslations('activeUsers');

  if (rows.length === 0) {
    return <p className={styles.empty}>{t('noActiveUsers')}</p>;
  }

  return (
    <div className={styles.wrap}>
      <table className={styles.table}>
        <thead>
          <tr>
            <th>{t('user')}</th>
            <th>{t('status')}</th>
            <th>{t('screen')}</th>
            <th>{t('platform')}</th>
            <th>{t('location')}</th>
            <th>{t('lastActivity')}</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              <td>
                <strong>{row.firstName} {row.lastName}</strong>
                <div className={styles.sub}>{row.email}</div>
              </td>
              <td><span className={styles[`status_${row.status}`]}>{row.status}</span></td>
              <td>{row.currentScreen ?? '—'}</td>
              <td>{row.platform ?? '—'} {row.appVersion ? `(${row.appVersion})` : ''}</td>
              <td>{[row.city, row.country].filter(Boolean).join(', ') || '—'}</td>
              <td>{new Date(row.lastActivity).toLocaleTimeString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
