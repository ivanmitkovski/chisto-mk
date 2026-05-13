import type { GeoIntentBounds } from './sites-map-search.types';

type GeoIntentEntry = {
  aliases: string[];
  bounds: GeoIntentBounds;
};

/**
 * Covers all major Macedonian cities/municipalities with both Latin and
 * Cyrillic name variants. Bounding boxes are generous enough to be useful
 * for the client map viewport.
 */
const GEO_INTENT_CATALOG: GeoIntentEntry[] = [
  {
    aliases: ['skopje', 'скопје'],
    bounds: { label: 'Skopje', minLat: 41.93, maxLat: 42.07, minLng: 21.33, maxLng: 21.57 },
  },
  {
    aliases: ['bitola', 'битола'],
    bounds: { label: 'Bitola', minLat: 40.98, maxLat: 41.08, minLng: 21.28, maxLng: 21.42 },
  },
  {
    aliases: ['ohrid', 'охрид'],
    bounds: { label: 'Ohrid', minLat: 41.06, maxLat: 41.16, minLng: 20.75, maxLng: 20.85 },
  },
  {
    aliases: ['prilep', 'прилеп'],
    bounds: { label: 'Prilep', minLat: 41.28, maxLat: 41.4, minLng: 21.5, maxLng: 21.62 },
  },
  {
    aliases: ['kumanovo', 'куманово'],
    bounds: { label: 'Kumanovo', minLat: 42.08, maxLat: 42.18, minLng: 21.67, maxLng: 21.81 },
  },
  {
    aliases: ['tetovo', 'тетово'],
    bounds: { label: 'Tetovo', minLat: 41.98, maxLat: 42.06, minLng: 20.9, maxLng: 21.02 },
  },
  {
    aliases: ['veles', 'велес'],
    bounds: { label: 'Veles', minLat: 41.68, maxLat: 41.77, minLng: 21.73, maxLng: 21.82 },
  },
  {
    aliases: ['stip', 'shtip', 'штип'],
    bounds: { label: 'Shtip', minLat: 41.7, maxLat: 41.78, minLng: 22.15, maxLng: 22.24 },
  },
  {
    aliases: ['strumica', 'струмица'],
    bounds: { label: 'Strumica', minLat: 41.4, maxLat: 41.5, minLng: 22.6, maxLng: 22.7 },
  },
  {
    aliases: ['gostivar', 'гостивар'],
    bounds: { label: 'Gostivar', minLat: 41.76, maxLat: 41.84, minLng: 20.86, maxLng: 20.97 },
  },
  {
    aliases: ['kavadarci', 'кавадарци'],
    bounds: { label: 'Kavadarci', minLat: 41.4, maxLat: 41.48, minLng: 21.98, maxLng: 22.05 },
  },
  {
    aliases: ['kochani', 'кочани'],
    bounds: { label: 'Kochani', minLat: 41.87, maxLat: 41.96, minLng: 22.36, maxLng: 22.46 },
  },
  {
    aliases: ['kichevo', 'кичево'],
    bounds: { label: 'Kichevo', minLat: 41.48, maxLat: 41.55, minLng: 20.91, maxLng: 21.0 },
  },
  {
    aliases: ['struga', 'струга'],
    bounds: { label: 'Struga', minLat: 41.13, maxLat: 41.22, minLng: 20.63, maxLng: 20.72 },
  },
  {
    aliases: ['gevgelija', 'гевгелија'],
    bounds: { label: 'Gevgelija', minLat: 41.11, maxLat: 41.18, minLng: 22.46, maxLng: 22.54 },
  },
  {
    aliases: ['negotino', 'неготино'],
    bounds: { label: 'Negotino', minLat: 41.45, maxLat: 41.52, minLng: 22.06, maxLng: 22.14 },
  },
  {
    aliases: ['debar', 'дебар'],
    bounds: { label: 'Debar', minLat: 41.49, maxLat: 41.56, minLng: 20.49, maxLng: 20.56 },
  },
  {
    aliases: ['kratovo', 'кратово'],
    bounds: { label: 'Kratovo', minLat: 42.05, maxLat: 42.12, minLng: 22.15, maxLng: 22.22 },
  },
  {
    aliases: ['krusevo', 'крушево'],
    bounds: { label: 'Krusevo', minLat: 41.33, maxLat: 41.41, minLng: 21.22, maxLng: 21.29 },
  },
  {
    aliases: ['demir hisar', 'демир хисар'],
    bounds: { label: 'Demir Hisar', minLat: 41.18, maxLat: 41.25, minLng: 21.16, maxLng: 21.24 },
  },
  {
    aliases: ['resen', 'ресен'],
    bounds: { label: 'Resen', minLat: 41.05, maxLat: 41.13, minLng: 20.98, maxLng: 21.06 },
  },
  {
    aliases: ['probistip', 'пробиштип'],
    bounds: { label: 'Probistip', minLat: 41.95, maxLat: 42.03, minLng: 22.14, maxLng: 22.22 },
  },
  {
    aliases: ['sveti nikole', 'свети николе'],
    bounds: { label: 'Sveti Nikole', minLat: 41.82, maxLat: 41.9, minLng: 21.91, maxLng: 21.99 },
  },
  {
    aliases: ['berovo', 'берово'],
    bounds: { label: 'Berovo', minLat: 41.68, maxLat: 41.75, minLng: 22.81, maxLng: 22.89 },
  },
  {
    aliases: ['radovis', 'radovish', 'радовиш'],
    bounds: { label: 'Radovis', minLat: 41.61, maxLat: 41.68, minLng: 22.43, maxLng: 22.51 },
  },
  {
    aliases: ['valandovo', 'валандово'],
    bounds: { label: 'Valandovo', minLat: 41.28, maxLat: 41.36, minLng: 22.52, maxLng: 22.6 },
  },
  {
    aliases: ['delcevo', 'делчево'],
    bounds: { label: 'Delcevo', minLat: 41.94, maxLat: 42.01, minLng: 22.74, maxLng: 22.82 },
  },
  {
    aliases: ['vinica', 'виница'],
    bounds: { label: 'Vinica', minLat: 41.85, maxLat: 41.92, minLng: 22.46, maxLng: 22.54 },
  },
  {
    aliases: ['makedonski brod', 'македонски брод'],
    bounds: { label: 'Makedonski Brod', minLat: 41.48, maxLat: 41.56, minLng: 21.2, maxLng: 21.28 },
  },
];

/** Approximate km-per-degree at Macedonian latitudes (~41°N). */
export const MAP_SEARCH_KM_PER_DEGREE = 111.0;

export function resolveGeoIntentFromQuery(q: string): GeoIntentBounds | null {
  const lower = q.toLowerCase();
  for (const entry of GEO_INTENT_CATALOG) {
    if (entry.aliases.some((alias) => lower.includes(alias))) {
      return entry.bounds;
    }
  }
  return null;
}
