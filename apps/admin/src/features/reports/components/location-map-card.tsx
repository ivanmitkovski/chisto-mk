'use client';

import dynamic from 'next/dynamic';
import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import type { ReportMapPin } from '../types';
import styles from './location-map-card.module.css';

const LocationMapInner = dynamic(
  () => import('./location-map-inner').then((m) => ({ default: m.LocationMapInner })),
  {
    ssr: false,
    loading: () => <div className={styles.mapSkeleton} aria-hidden />,
  },
);

export type LocationMapCardProps = {
  mapPin: ReportMapPin;
  locationLabel: string;
};

export function LocationMapCard({ mapPin, locationLabel }: LocationMapCardProps) {
  const t = useTranslations('reports.locationMap');
  const tCommon = useTranslations('common');
  const osmUrl = `https://www.openstreetmap.org/?mlat=${mapPin.latitude}&mlon=${mapPin.longitude}#map=15/${mapPin.latitude}/${mapPin.longitude}`;
  const googleUrl = `https://www.google.com/maps?q=${mapPin.latitude},${mapPin.longitude}`;

  return (
    <div className={styles.card}>
      <h3 className={styles.title}>{t('title')}</h3>
      <p className={styles.subtitle}>{locationLabel}</p>
      <LocationMapInner mapPin={mapPin} locationLabel={locationLabel} />
      <div className={styles.links}>
        <a
          href={googleUrl}
          target="_blank"
          rel="noreferrer noopener"
          className={styles.link}
        >
          {tCommon('openInGoogleMaps')}
          <Icon name="document-forward" size={14} />
        </a>
        <a
          href={osmUrl}
          target="_blank"
          rel="noreferrer noopener"
          className={styles.linkSecondary}
        >
          {t('openInOpenStreetMap')}
          <Icon name="document-forward" size={14} />
        </a>
      </div>
    </div>
  );
}
