'use client';

import type { RefObject } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon, Input } from '@/components/ui';
import type { ConfigEntry } from '@/features/settings/data/config-adapter';
import panelStyles from './settings-panel.module.css';
import styles from './settings-environment-panel.module.css';

type SettingsEnvironmentPanelProps = {
  isSuperAdmin: boolean;
  rows: ConfigEntry[];
  busy: boolean;
  panelTitleRef: RefObject<HTMLHeadingElement | null>;
  onRowValueChange: (index: number, value: string) => void;
  onSave: () => void;
};

export function SettingsEnvironmentPanel({
  isSuperAdmin,
  rows,
  busy,
  panelTitleRef,
  onRowValueChange,
  onSave,
}: SettingsEnvironmentPanelProps) {
  const t = useTranslations('settings.environment');
  const tCommon = useTranslations('common');

  return (
    <div className={panelStyles.panel}>
      <header className={panelStyles.panelHeader}>
        <h2 ref={panelTitleRef} className={panelStyles.panelTitle} tabIndex={-1}>
          {t('title')}
        </h2>
        <p className={panelStyles.panelDescription}>{t('description')}</p>
      </header>
      {!isSuperAdmin ? (
        <div className={panelStyles.restricted}>
          <Icon name="shield" size={48} />
          <p>{t('restricted')}</p>
        </div>
      ) : (
        <section className={panelStyles.section}>
          <h3 className={panelStyles.sectionTitle}>{t('configEntriesTitle')}</h3>
          <div className={panelStyles.insetGroup}>
            {rows.map((row, i) => (
              <div key={row.key} className={styles.configRow}>
                <label htmlFor={`cfg-${row.key}`} className={styles.configLabel}>
                  {row.key}
                </label>
                <Input
                  id={`cfg-${row.key}`}
                  value={row.value}
                  onChange={(e) => onRowValueChange(i, e.target.value)}
                />
              </div>
            ))}
          </div>
          <Button onClick={() => void onSave()} disabled={busy}>
            {busy ? tCommon('saving') : t('saveConfiguration')}
          </Button>
        </section>
      )}
    </div>
  );
}
