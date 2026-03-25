'use client';

import { useCallback, useEffect, useState, type RefObject } from 'react';
import { Icon } from '@/components/ui';
import {
  getReducedMotionPreference,
  getReportSoundPreference,
  setReducedMotionPreference,
  setReportSoundPreference,
} from '@/lib/admin-preferences';
import styles from './settings-console.module.css';

type SettingsPreferencesSectionProps = {
  panelTitleRef?: RefObject<HTMLHeadingElement | null>;
};

export function SettingsPreferencesSection({ panelTitleRef }: SettingsPreferencesSectionProps) {
  const [reduceMotion, setReduceMotion] = useState(false);
  const [reportSound, setReportSound] = useState(false);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    try {
      setReduceMotion(getReducedMotionPreference());
      setReportSound(getReportSoundPreference());
    } catch {
      setReduceMotion(false);
      setReportSound(false);
    }
    setHydrated(true);
  }, []);

  const onToggleReduceMotion = useCallback((next: boolean) => {
    setReduceMotion(next);
    setReducedMotionPreference(next);
  }, []);

  const onToggleReportSound = useCallback((next: boolean) => {
    setReportSound(next);
    setReportSoundPreference(next);
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
          Per-browser toggles for live report alerts. This does not change settings on other devices.
        </p>
        <div className={styles.preferenceRow}>
          <div className={styles.preferenceText}>
            <span className={styles.preferenceTitle}>Sound on new reports</span>
            <span className={styles.preferenceCaption}>
              Plays a subtle chime when a new report arrives in real time
            </span>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={reportSound}
            disabled={!hydrated}
            className={`${styles.toggle} ${reportSound ? styles.toggleOn : ''}`}
            onClick={() => onToggleReportSound(!reportSound)}
          >
            <span className={styles.toggleThumb} />
          </button>
        </div>
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
