'use client';

import type { RefObject } from 'react';
import { useTranslations } from 'next-intl';
import type { FeatureFlagRow } from '@/features/settings/data/feature-flags-adapter';
import { getFeatureFlagDescription } from '@/features/settings/lib/settings-display';
import { useReadOnlyUnless } from '@/lib/auth/rbac/use-read-only-unless';
import panelStyles from './settings-panel.module.css';
import styles from './settings-feature-flags-panel.module.css';

type SettingsFeatureFlagsPanelProps = {
  flags: FeatureFlagRow[];
  busyKey: string | null;
  panelTitleRef: RefObject<HTMLHeadingElement | null>;
  onToggle: (key: string, enabled: boolean) => void;
};

export function SettingsFeatureFlagsPanel({
  flags,
  busyKey,
  panelTitleRef,
  onToggle,
}: SettingsFeatureFlagsPanelProps) {
  const t = useTranslations('settings.featureFlags');
  const readOnly = useReadOnlyUnless('feature-flags:write');

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
            {flags.map((f) => {
              const descStr = getFeatureFlagDescription(f.metadata);
              return (
                <li key={f.key} className={styles.flagItem}>
                  <div className={styles.flagInfo}>
                    <span className={styles.flagKey}>{f.key}</span>
                    {descStr != null ? <span className={styles.flagDesc}>{descStr}</span> : null}
                  </div>
                  <button
                    type="button"
                    role="switch"
                    aria-checked={f.enabled}
                    aria-label={t('toggleAria', { name: f.key })}
                    disabled={readOnly || busyKey === f.key}
                    aria-readonly={readOnly}
                    className={`${styles.toggle} ${f.enabled ? styles.toggleOn : ''}`}
                    onClick={() => void onToggle(f.key, !f.enabled)}
                  >
                    <span className={styles.toggleThumb} />
                  </button>
                </li>
              );
            })}
          </ul>
          {flags.length === 0 ? (
            <p className={panelStyles.empty}>{t('empty')}</p>
          ) : null}
        </div>
      </section>
    </div>
  );
}
