'use client';

import { useTranslations } from 'next-intl';
import { Spinner } from '@/components/ui/spinner/spinner';
import styles from './sites-map.module.css';

export function MapLoadingFallback() {
  const t = useTranslations('map');

  return (
    <div className={styles.mapWrap}>
      <div
        className={`${styles.overlay} ${styles.loadingOverlay}`}
        role="status"
        aria-live="polite"
        aria-busy="true"
      >
        <div className={styles.overlayContent}>
          <Spinner aria-label={t('loadingMap')} />
          <span className={styles.overlayMessage}>{t('loadingMap')}…</span>
        </div>
      </div>
    </div>
  );
}
