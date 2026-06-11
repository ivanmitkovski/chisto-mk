'use client';

import { useTranslations } from 'next-intl';
import type { AdminAlertRule } from '../data/active-users.types';
import styles from './alerts-panel.module.css';

export function AlertsPanel({ rules }: { rules: AdminAlertRule[] }) {
  const t = useTranslations('activeUsers');

  return (
    <section className={styles.panel}>
      <h3>{t('alerts')}</h3>
      {rules.length === 0 ? (
        <p className={styles.empty}>{t('noAlerts')}</p>
      ) : (
        <ul className={styles.list}>
          {rules.map((rule) => (
            <li key={rule.id} className={styles.item}>
              <strong>{rule.metric}</strong>
              <span>{rule.comparator} {rule.threshold}</span>
              <span className={rule.enabled ? styles.enabled : styles.disabled}>
                {rule.enabled ? t('enabled') : t('disabled')}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
