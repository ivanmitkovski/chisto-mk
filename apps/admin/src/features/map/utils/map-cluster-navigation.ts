import L from 'leaflet';

/** Match `disableClusteringAtZoom` on the map — zoom in at least this far for tight clusters. */
export const CLUSTER_EXPAND_MIN_ZOOM = 15;

const LOOSE_CLUSTER_MIN_ZOOM = 6;
const TIGHT_SPAN_DEG_THRESHOLD = 0.03;
const MIN_POINT_SPAN_DEG = 0.002;
const PADDING_PX = 56;
const FLY_DURATION_SEC = 0.52;
const FLY_EASE_LINEARITY = 0.22;

type MarkerClusterLayer = L.Layer & {
  getAllChildMarkers(): L.Marker[];
  getLatLng(): L.LatLng;
};

function isMarkerClusterLayer(layer: L.Layer): layer is MarkerClusterLayer {
  return typeof (layer as MarkerClusterLayer).getAllChildMarkers === 'function';
}

/**
 * Mirrors mobile `PollutionMapScreen._expandClusterToShowSites` / cluster tap:
 * smooth fly, recenter on cluster contents, enforce min zoom for tight groups.
 */
export function flyToClusterContents(map: L.Map, clusterLayer: L.Layer): void {
  if (!isMarkerClusterLayer(clusterLayer)) return;

  const maxZ = map.getMaxZoom();
  if (map.getZoom() >= maxZ) {
    return;
  }

  const markers = clusterLayer.getAllChildMarkers();
  const latlngs = markers.map((m) => m.getLatLng()).filter(Boolean);
  if (latlngs.length === 0) return;

  const reducedMotion =
    typeof window !== 'undefined' &&
    window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  const duration = reducedMotion ? 0 : FLY_DURATION_SEC;

  if (latlngs.length === 1) {
    const ll = latlngs[0];
    const nextZoom = Math.min(18, Math.max(3, map.getZoom() + 2));
    map.flyTo(ll, nextZoom, { duration, easeLinearity: FLY_EASE_LINEARITY });
    return;
  }

  let minLat = latlngs[0].lat;
  let maxLat = latlngs[0].lat;
  let minLng = latlngs[0].lng;
  let maxLng = latlngs[0].lng;
  for (const p of latlngs) {
    minLat = Math.min(minLat, p.lat);
    maxLat = Math.max(maxLat, p.lat);
    minLng = Math.min(minLng, p.lng);
    maxLng = Math.max(maxLng, p.lng);
  }

  const spanLat = Math.abs(maxLat - minLat);
  const spanLng = Math.abs(maxLng - minLng);
  const padLat = spanLat < MIN_POINT_SPAN_DEG ? MIN_POINT_SPAN_DEG - spanLat : 0;
  const padLng = spanLng < MIN_POINT_SPAN_DEG ? MIN_POINT_SPAN_DEG - spanLng : 0;

  const bounds = L.latLngBounds(
    [minLat - padLat / 2, minLng - padLng / 2],
    [maxLat + padLat / 2, maxLng + padLng / 2],
  );

  const spanDeg = Math.sqrt(spanLat * spanLat + spanLng * spanLng);
  const isTightCluster = spanDeg < TIGHT_SPAN_DEG_THRESHOLD;
  const floorZoom = isTightCluster ? CLUSTER_EXPAND_MIN_ZOOM : LOOSE_CLUSTER_MIN_ZOOM;

  const padding = L.point(PADDING_PX, PADDING_PX);
  let targetZoom = map.getBoundsZoom(bounds, false, padding);
  targetZoom = Math.min(18, Math.max(floorZoom, targetZoom));

  const center = bounds.getCenter();
  map.flyTo(center, targetZoom, { duration, easeLinearity: FLY_EASE_LINEARITY });
}
