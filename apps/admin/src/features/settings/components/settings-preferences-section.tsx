'use client';

import { useCallback, useEffect, useState, useTransition, type RefObject } from 'react';
import { useLocale, useTranslations } from 'next-intl';
import { useRouter } from 'next/navigation';
import { Icon } from '@/components/ui';
import { setAdminLocale } from '@/i18n/locale-actions';
import {
  ADMIN_LOCALE_DISPLAY_NAMES,
  ADMIN_LOCALES,
  getReducedMotionPreference,
  getReportSoundPreference,
  setReducedMotionPreference,
  setReportSoundPreference,
  writeLocaleToStorage,
  type AdminLocale,
} from '@/lib/preferences';
import {
  playReportChimePreview,
  unlockReportAudioFromUserGesture,
} from '@/lib/realtime';
import styles from './settings-preferences-section.module.css';
import panelStyles from './settings-panel.module.css';

const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

type SettingsPreferencesSectionProps = {
  panelTitleRef?: RefObject<HTMLHeadingElement | null>;
};

export function SettingsPreferencesSection({ panelTitleRef }: SettingsPreferencesSectionProps) {
  const t = useTranslations('settings.preferences');
  const locale = useLocale() as AdminLocale;
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
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
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] settings-toggle-sound', { enabled: next });
    }
    if (next) {
      void unlockReportAudioFromUserGesture().then((ok) => {
        if (isRealtimeDebugEnabled()) {
          console.info('[realtime] settings-unlock-result', { ok });
        }
        if (ok) {
          playReportChimePreview();
          if (isRealtimeDebugEnabled()) {
            console.info('[realtime] settings-play-test', { source: 'toggle-on' });
          }
        }
      });
    }
  }, []);

  const onTestReportSound = useCallback(() => {
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] settings-play-test-click');
    }
    void unlockReportAudioFromUserGesture().then((ok) => {
      if (isRealtimeDebugEnabled()) {
        console.info('[realtime] settings-unlock-result', { ok });
      }
      if (ok) {
        playReportChimePreview();
        if (isRealtimeDebugEnabled()) {
          console.info('[realtime] settings-play-test', { source: 'button' });
        }
      }
    });
  }, []);

  const onLocaleChange = useCallback(
    (nextLocale: AdminLocale) => {
      if (nextLocale === locale) return;
      writeLocaleToStorage(nextLocale);
      startTransition(async () => {
        const result = await setAdminLocale(nextLocale);
        if (result.ok) {
          router.refresh();
        }
      });
    },
    [locale, router],
  );

  return (
    <>
      <header className={panelStyles.panelHeader}>
        <h2 ref={panelTitleRef} className={panelStyles.panelTitle} tabIndex={-1}>
          {t('title')}
        </h2>
        <p className={panelStyles.panelDescription}>{t('description')}</p>
      </header>

      <section className={panelStyles.section}>
        <span className={panelStyles.sectionLabel}>{t('displayLabel')}</span>
        <h3 className={panelStyles.sectionTitle}>{t('interfaceMotionTitle')}</h3>
        <p className={panelStyles.sectionHint}>{t('interfaceMotionHint')}</p>
        <div className={styles.preferenceRow}>
          <div className={styles.preferenceText}>
            <span className={styles.preferenceTitle}>{t('reduceMotionTitle')}</span>
            <span className={styles.preferenceCaption}>{t('reduceMotionCaption')}</span>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={reduceMotion}
            aria-label={t('reduceMotionToggleAria')}
            disabled={!hydrated}
            className={`${styles.toggle} ${reduceMotion ? styles.toggleOn : ''}`}
            onClick={() => onToggleReduceMotion(!reduceMotion)}
          >
            <span className={styles.toggleThumb} />
          </button>
        </div>
      </section>

      <section className={panelStyles.section}>
        <span className={panelStyles.sectionLabel}>{t('notificationsLabel')}</span>
        <h3 className={panelStyles.sectionTitle}>{t('deliveryPreferencesTitle')}</h3>
        <p className={panelStyles.sectionHint}>{t('deliveryPreferencesHint')}</p>
        <div className={styles.preferenceRow}>
          <div className={styles.preferenceText}>
            <span className={styles.preferenceTitle}>{t('soundOnNewReportsTitle')}</span>
            <span className={styles.preferenceCaption}>{t('soundOnNewReportsCaption')}</span>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={reportSound}
            aria-label={t('soundOnNewReportsToggleAria')}
            disabled={!hydrated}
            className={`${styles.toggle} ${reportSound ? styles.toggleOn : ''}`}
            onClick={() => onToggleReportSound(!reportSound)}
          >
            <span className={styles.toggleThumb} />
          </button>
        </div>
        {reportSound ? (
          <button
            type="button"
            className={styles.soundTestButton}
            disabled={!hydrated}
            onClick={onTestReportSound}
          >
            {t('playTestSound')}
          </button>
        ) : null}
        <div className={styles.preferenceNote}>
          <Icon name="info" size={18} />
          <p>{t('serverAlertsNote')}</p>
        </div>
      </section>

      <section className={panelStyles.section}>
        <span className={panelStyles.sectionLabel}>{t('languageLabel')}</span>
        <h3 className={panelStyles.sectionTitle}>{t('localeTitle')}</h3>
        <p className={panelStyles.sectionHint}>{t('localeHint')}</p>
        <label className={styles.preferenceSelectLabel} htmlFor="settings-locale">
          {t('displayLanguage')}
        </label>
        <select
          id="settings-locale"
          className={styles.preferenceSelect}
          value={locale}
          disabled={!hydrated || isPending}
          onChange={(event) => onLocaleChange(event.target.value as AdminLocale)}
        >
          {ADMIN_LOCALES.map((code) => (
            <option key={code} value={code}>
              {ADMIN_LOCALE_DISPLAY_NAMES[code]}
            </option>
          ))}
        </select>
        <p className={styles.preferenceFootnote}>{t('localeFootnote')}</p>
      </section>
    </>
  );
}
