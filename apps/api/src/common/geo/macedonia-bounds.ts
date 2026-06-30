/**
 * Shared North Macedonia bounding box, used everywhere the server must decide whether
 * a coordinate is "inside the country" (home-location onboarding, report submit,
 * event check-in, and home-location onboarding).
 *
 * This is intentionally a coarse rectangle (matches the mobile onboarding map and the
 * report geofence) - it is a server-side guard, not a precise polygon. Keep this the
 * single source of truth so the client and server never drift.
 */
export const MACEDONIA_BOUNDS = {
  minLat: 40.8,
  maxLat: 42.4,
  minLng: 20.4,
  maxLng: 23.1,
} as const;

/** Returns true when the WGS84 coordinate falls inside the North Macedonia bounding box. */
export function isWithinMacedonia(latitude: number, longitude: number): boolean {
  return (
    Number.isFinite(latitude) &&
    Number.isFinite(longitude) &&
    latitude >= MACEDONIA_BOUNDS.minLat &&
    latitude <= MACEDONIA_BOUNDS.maxLat &&
    longitude >= MACEDONIA_BOUNDS.minLng &&
    longitude <= MACEDONIA_BOUNDS.maxLng
  );
}
