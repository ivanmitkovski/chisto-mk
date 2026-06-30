'use client';

import dynamic from 'next/dynamic';
import { MapLoadingFallback } from './map-loading-fallback';

export const MapWorkspaceLazy = dynamic(
  () => import('./map-workspace').then((module) => ({ default: module.MapWorkspace })),
  { ssr: false, loading: () => <MapLoadingFallback /> },
);
