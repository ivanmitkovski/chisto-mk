import { describe, expect, it } from 'vitest';

import { MACEDONIA_CENTER, INITIAL_ZOOM, SERVER_CLUSTER_MAX_ZOOM } from '../map-constants';
import { parseViewportFromSearchParams, radiusKmFromZoom } from './map-viewport-url';

/**
 * Pure viewport + radius helpers used by `useSitesMap` (React hook integration
 * is covered indirectly via map-adapter ETag tests + Playwright a11y gate).
 */
describe('useSitesMap viewport helpers (map-viewport-url)', () => {
  it('radiusKmFromZoom clamps zoom and maps known levels', () => {
    expect(radiusKmFromZoom(10)).toBe(60);
    expect(radiusKmFromZoom(3)).toBe(radiusKmFromZoom(6));
    expect(radiusKmFromZoom(99)).toBe(radiusKmFromZoom(18));
  });

  it('parseViewportFromSearchParams reads lat/lng/z for Macedonia', () => {
    const sp = new URLSearchParams('lat=41.90000&lng=21.40000&z=10');
    const v = parseViewportFromSearchParams(sp);
    expect(v.center[0]).toBeCloseTo(41.9, 5);
    expect(v.center[1]).toBeCloseTo(21.4, 5);
    expect(v.zoom).toBe(10);
  });

  it('parseViewportFromSearchParams falls back when coords are out of bounds', () => {
    const sp = new URLSearchParams('lat=5&lng=5&z=10');
    const v = parseViewportFromSearchParams(sp);
    expect(v.center[0]).toBe(MACEDONIA_CENTER[0]);
    expect(v.center[1]).toBe(MACEDONIA_CENTER[1]);
    expect(v.zoom).toBe(INITIAL_ZOOM);
  });

  it('zoom at SERVER_CLUSTER_MAX_ZOOM uses cluster mode threshold in hook (boundary)', () => {
    expect(SERVER_CLUSTER_MAX_ZOOM).toBe(8);
    const sp = new URLSearchParams('lat=41.90000&lng=21.40000&z=8');
    expect(parseViewportFromSearchParams(sp).zoom).toBe(8);
  });
});
