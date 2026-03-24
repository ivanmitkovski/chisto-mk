'use client';

import dynamic from 'next/dynamic';
import { Spinner } from '@/components/ui/spinner/spinner';
import styles from './sites-map.module.css';

export const SitesMap = dynamic(
  () => import('./sites-map').then((m) => ({ default: m.SitesMap })),
  {
    ssr: false,
    loading: () => (
      <div className={styles.mapWrap}>
        <div
          className={styles.overlay}
          style={{ background: 'rgba(247, 250, 255, 0.9)' }}
          role="status"
          aria-live="polite"
          aria-busy="true"
        >
          <div className={styles.overlayContent}>
            <Spinner aria-label="Loading map" />
            <span className={styles.overlayMessage}>Loading map…</span>
          </div>
        </div>
      </div>
    ),
  },
);
