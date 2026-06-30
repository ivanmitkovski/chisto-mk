'use client';

import { useEffect, useState } from 'react';

export const CARTODB_POSITRON =
  'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}{r}.png';

function readCssTileTemplateLight(): string | null {
  if (typeof window === 'undefined') {
    return null;
  }
  const raw = getComputedStyle(document.documentElement)
    .getPropertyValue('--map-tile-template-light')
    .trim();
  if (!raw) {
    return null;
  }
  return raw.replace(/^['"]|['"]$/g, '');
}

/** Admin is light-only for now; always use the light basemap (CSS var or Carto Positron). */
export function useTileUrl(): string {
  const [fromCss, setFromCss] = useState<string | null>(null);

  useEffect(() => {
    setFromCss(readCssTileTemplateLight());
  }, []);

  return fromCss ?? CARTODB_POSITRON;
}
