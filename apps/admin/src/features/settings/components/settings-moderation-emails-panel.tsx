'use client';

import type { RefObject } from 'react';
import { useTranslations } from 'next-intl';
import type {
  ModerationEmailCategory,
  ModerationEmailPreferenceRow,
} from '@/features/settings/data/moderation-email-preferences.types';
import panelStyles from './settings-panel.module.css';
import styles from './settings-feature-flags-panel.module.css';

type SettingsModerationEmailsPanelProps = {
  rows: ModerationEmailPreferenceRow[];
  busyCategory: ModerationEmailCategory | null;
  panelTitleRef: RefObject<HTMLHeadingElement | null>;
  onToggle: (category: ModerationEmailCategory, enabled: boolean) => void;
};

export function SettingsModerationEmailsPanel({
  rows,
  busyCategory,
  panelTitleRef,
  onToggle,
}: SettingsModerationEmailsPanelProps) {
  const t = useTranslations('settings.moderationEmails');

  return (
    <div className={panelStyles.panel}>
      <header className={panelStyles.panelHeader}>
        <h2 ref={panelTitleRef} className={panelStyles.panelTitle} tabIndex={-1}>
          {t('title')}
        </h2>
        <p className={panelStyles.panelDescription}>{t('description')}</p>
      </header>
      <section className={panelStyles.section}>
        <div className={panelStyles.insetGroup}>
          <ul className={styles.flagList}>
            {rows.map((row) => (
              <li key={row.category} className={styles.flagItem}>
                <div className={styles.flagInfo}>
                  <span className={styles.flagKey}>{t(`categories.${row.category}.title`)}</span>
                  <span className={styles.flagDesc}>
                    {t(`categories.${row.category}.description`)}
                    {row.source === 'default' ? ` · ${t('defaultForRole')}` : ''}
                  </span>
                </div>
                <button
                  type="button"
                  role="switch"
                  aria-checked={row.enabled}
                  aria-label={t('notificationsAria', { title: t(`categories.${row.category}.title`) })}
                  disabled={busyCategory === row.category}
                  className={`${styles.toggle} ${row.enabled ? styles.toggleOn : ''}`}
                  onClick={() => void onToggle(row.category, !row.enabled)}
                >
                  <span className={styles.toggleThumb} />
                </button>
              </li>
            ))}
          </ul>
          {rows.length === 0 ? (
            <p className={panelStyles.empty}>{t('loadError')}</p>
          ) : null}
        </div>
      </section>
    </div>
  );
}
