export const MACEDONIA_CENTER = [41.6086, 21.7453] as const;
export const MACEDONIA_BOUNDS = {
  minLat: 40.8,
  maxLat: 42.4,
  minLng: 20.4,
  maxLng: 23.1,
};
export const INITIAL_ZOOM = 8;

/** Server returns synthetic cluster rows at this zoom and below (see `useSitesMap`). */
export const SERVER_CLUSTER_MAX_ZOOM = 8;
