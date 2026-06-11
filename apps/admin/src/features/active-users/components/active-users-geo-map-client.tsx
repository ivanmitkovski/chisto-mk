'use client';

import dynamic from 'next/dynamic';
import { MapLoadingFallback } from '@/features/map/components/map-loading-fallback';
import styles from './active-users-geo-map.module.css';

export const ActiveUsersGeoMap = dynamic(
  () => import('./active-users-geo-map').then((m) => ({ default: m.ActiveUsersGeoMap })),
  {
    ssr: false,
    loading: () => (
      <div className={styles.embed}>
        <MapLoadingFallback />
      </div>
    ),
  },
);
