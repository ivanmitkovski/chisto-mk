'use client';

import dynamic from 'next/dynamic';
import { MapLoadingFallback } from './map-loading-fallback';

export const SitesMap = dynamic(
  () => import('./sites-map').then((m) => ({ default: m.SitesMap })),
  {
    ssr: false,
    loading: () => <MapLoadingFallback />,
  },
);
