'use client';

import { createPortal } from 'react-dom';
import { useTranslations } from 'next-intl';
import { useMap } from 'react-leaflet';
import { Icon } from '@/components/ui';
import styles from './sites-map.module.css';

export function MapZoomControls() {
  const map = useMap();
  const t = useTranslations('map');

  return createPortal(
    <div className={styles.zoomControl} role="group" aria-label={t('zoom.groupAria')}>
      <button
        type="button"
        className={styles.zoomBtn}
        onClick={() => map.zoomIn()}
        aria-label={t('zoom.in')}
      >
        <Icon name="plus" size={18} />
      </button>
      <span className={styles.zoomDivider} aria-hidden />
      <button
        type="button"
        className={styles.zoomBtn}
        onClick={() => map.zoomOut()}
        aria-label={t('zoom.out')}
      >
        <Icon name="minus" size={18} />
      </button>
    </div>,
    map.getContainer(),
  );
}
