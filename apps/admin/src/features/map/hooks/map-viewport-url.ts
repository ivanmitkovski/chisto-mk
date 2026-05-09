import { MACEDONIA_BOUNDS, MACEDONIA_CENTER, INITIAL_ZOOM } from '../map-constants';

/** Approximate radius in km for a zoom level (Leaflet). Used by [useSitesMap] query key + API radius. */
export function radiusKmFromZoom(zoom: number): number {
  const lookup: Record<number, number> = {
    6: 260,
    7: 180,
    8: 120,
    9: 90,
    10: 60,
    11: 40,
    12: 28,
    13: 20,
    14: 14,
    15: 10,
    16: 7,
    17: 5,
    18: 3,
  };
  const z = Math.round(Math.min(18, Math.max(6, zoom)));
  return lookup[z] ?? 80;
}

/** Parses `lat` / `lng` / `z` search params into a bounded Macedonia viewport. */
export function parseViewportFromSearchParams(
  sp: URLSearchParams,
): { center: [number, number]; zoom: number } {
  const lat = Number(sp.get('lat'));
  const lng = Number(sp.get('lng'));
  const z = Number(sp.get('z'));
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return { center: [...MACEDONIA_CENTER], zoom: INITIAL_ZOOM };
  }
  if (
    lat < MACEDONIA_BOUNDS.minLat ||
    lat > MACEDONIA_BOUNDS.maxLat ||
    lng < MACEDONIA_BOUNDS.minLng ||
    lng > MACEDONIA_BOUNDS.maxLng
  ) {
    return { center: [...MACEDONIA_CENTER], zoom: INITIAL_ZOOM };
  }
  const zoom = Number.isFinite(z) && z >= 6 && z <= 18 ? Math.round(z) : INITIAL_ZOOM;
  return { center: [lat, lng], zoom };
}
