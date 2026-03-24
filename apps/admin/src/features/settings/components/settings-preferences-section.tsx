'use client';

import { useCallback, useEffect, useState, type RefObject } from 'react';
import { Icon } from '@/components/ui';
import { ADMIN_REDUCED_MOTION_CLASS } from './admin-preferences-init';
import styles from './settings-console.module.css';

const STORAGE_KEY = 'chisto.admin.ui.reducedMotion';

type SettingsPreferencesSectionProps = {
  panelTitleRef?: RefObject<HTMLHeadingElement | null>;
};

export function SettingsPreferencesSection({ panelTitleRef }: SettingsPreferencesSectionProps) {
  const [reduceMotion, setReduceMotion] = useState(false);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    try {
      const v = window.localStorage.getItem(STORAGE_KEY) === '1';
      setReduceMotion(v);
      document.documentElement.classList.toggle(ADMIN_REDUCED_MOTION_CLASS, v);
    } catch {
      setReduceMotion(false);
    }
    setHydrated(true);
  }, []);

  const onToggleReduceMotion = useCallback((next: boolean) => {
    setReduceMotion(next);
    try {
      if (next) {
        window.localStorage.setItem(STORAGE_KEY, '1');
        document.documentElement.classList.add(ADMIN_REDUCED_MOTION_CLASS);
      } else {
        window.localStorage.removeItem(STORAGE_KEY);
        document.documentElement.classList.remove(ADMIN_REDUCED_MOTION_CLASS);
      }
    } catch {
      /* ignore */
    }
  }, []);

  return (
    <>
      <header className={styles.panelHeader}>
        <h2 ref={panelTitleRef} className={styles.panelTitle} tabIndex={-1}>
          Preferences
        </h2>
        <p className={styles.panelDescription}>
          Display options for this browser. Other devices are not affected.
        </p>
      </header>

      <section className={styles.section}>
        <span className={styles.sectionLabel}>Display</span>
        <h3 className={styles.sectionTitle}>Interface motion</h3>
        <p className={styles.sectionHint}>
          Shortens transitions across the admin app using design tokens. Stored only on this device.
        </p>
        <div className={styles.preferenceRow}>
          <div className={styles.preferenceText}>
            <span className={styles.preferenceTitle}>Reduce motion</span>
            <span className={styles.preferenceCaption}>Minimize animations and transitions</span>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={reduceMotion}
            disabled={!hydrated}
            className={`${styles.toggle} ${reduceMotion ? styles.toggleOn : ''}`}
            onClick={() => onToggleReduceMotion(!reduceMotion)}
          >
            <span className={styles.toggleThumb} />
          </button>
        </div>
      </section>

      <section className={styles.section}>
        <span className={styles.sectionLabel}>Notifications</span>
        <h3 className={styles.sectionTitle}>Delivery preferences</h3>
        <p className={styles.sectionHint}>
          Per-channel notification settings will use your account once the API exposes them. There is no backend field yet.
        </p>
        <div className={styles.preferenceNote}>
          <Icon name="info" size={18} />
          <p>Server-managed alerts still appear in the top bar and Notifications page.</p>
        </div>
      </section>

      <section className={styles.section}>
        <span className={styles.sectionLabel}>Language</span>
        <h3 className={styles.sectionTitle}>Locale</h3>
        <p className={styles.sectionHint}>Admin UI language.</p>
        <label className={styles.preferenceSelectLabel} htmlFor="settings-locale">
          Display language
        </label>
        <select id="settings-locale" className={styles.preferenceSelect} disabled defaultValue="en">
          <option value="en">English</option>
        </select>
        <p className={styles.preferenceFootnote}>Additional locales when product i18n ships.</p>
      </section>
    </>
  );
}
