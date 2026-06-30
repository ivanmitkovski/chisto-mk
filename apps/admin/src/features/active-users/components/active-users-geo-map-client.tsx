'use client';

import dynamic from 'next/dynamic';
import { MapLoadingFallback } from '@/features/map/components/map-loading-fallback';
import type { GeoCluster } from '../data/active-users.types';
import styles from './active-users-geo-map.module.css';

type ActiveUsersGeoMapProps = {
  clusters: GeoCluster[];
  loadError?: string;
};

export const ActiveUsersGeoMap = dynamic<ActiveUsersGeoMapProps>(
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
