/**
 * k6 load tests for all map endpoints with SLO thresholds.
 *
 * Modes (via __ENV.MODE):
 *   SMOKE (default) — 5 VUs per scenario, 1 minute
 *   LOAD            — ramping 0→50 VUs over 30s, sustain 3m, ramp down 30s
 *
 * Run:
 *   k6 run tools/k6/map_load.js
 *   k6 run -e MODE=LOAD -e API_BASE=https://api.chisto.mk tools/k6/map_load.js
 */
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.API_BASE || 'http://localhost:3000';
const MODE = (__ENV.MODE || 'SMOKE').toUpperCase();

// --- Macedonia bounds ---
const MK_LAT_MIN = 40.85;
const MK_LAT_MAX = 42.35;
const MK_LNG_MIN = 20.45;
const MK_LNG_MAX = 23.05;

// --- Helpers ---

function randomMacedoniaCoords() {
  return {
    lat: MK_LAT_MIN + Math.random() * (MK_LAT_MAX - MK_LAT_MIN),
    lng: MK_LNG_MIN + Math.random() * (MK_LNG_MAX - MK_LNG_MIN),
  };
}

function randomMacedoniaTile(z) {
  const n = Math.pow(2, z);
  const xMin = Math.floor(((MK_LNG_MIN + 180) / 360) * n);
  const xMax = Math.floor(((MK_LNG_MAX + 180) / 360) * n);
  const yMin = Math.floor(
    ((1 - Math.log(Math.tan((MK_LAT_MAX * Math.PI) / 180) + 1 / Math.cos((MK_LAT_MAX * Math.PI) / 180)) / Math.PI) / 2) * n,
  );
  const yMax = Math.floor(
    ((1 - Math.log(Math.tan((MK_LAT_MIN * Math.PI) / 180) + 1 / Math.cos((MK_LAT_MIN * Math.PI) / 180)) / Math.PI) / 2) * n,
  );
  const x = xMin + Math.floor(Math.random() * (xMax - xMin + 1));
  const y = yMin + Math.floor(Math.random() * (yMax - yMin + 1));
  return { x, y };
}

const SEARCH_QUERIES = [
  'Скопје',
  'Bitola',
  'Ohrid',
  'kumanvo',
  'vardr',
  'Тетово',
  'река',
  'депонија',
  'Прилеп',
  'zagaduvanje',
];

function randomSearchQuery() {
  return SEARCH_QUERIES[Math.floor(Math.random() * SEARCH_QUERIES.length)];
}

// --- Scenario executors ---

function smokeExecutor(exec) {
  return { executor: 'constant-vus', vus: 5, duration: '1m', exec };
}

function loadExecutor(exec) {
  return {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 50 },
      { duration: '3m', target: 50 },
      { duration: '30s', target: 0 },
    ],
    exec,
  };
}

function buildScenarios() {
  const pick = MODE === 'LOAD' ? loadExecutor : smokeExecutor;
  return {
    map_sites: pick('mapSites'),
    map_clusters: pick('mapClusters'),
    map_heatmap: pick('mapHeatmap'),
    map_mvt: pick('mapMvt'),
    map_search: pick('mapSearch'),
    map_sse: pick('mapSse'),
  };
}

// --- Options ---

export const options = {
  scenarios: buildScenarios(),
  thresholds: {
    'http_req_duration{scenario:map_sites}': ['p(95)<200'],
    'http_req_duration{scenario:map_clusters}': ['p(95)<200'],
    'http_req_duration{scenario:map_heatmap}': ['p(95)<300'],
    'http_req_duration{scenario:map_mvt}': ['p(95)<100'],
    'http_req_duration{scenario:map_search}': ['p(95)<300'],
    http_req_failed: ['rate<0.01'],
  },
};

// --- Setup ---

export function setup() {
  console.log(`Mode: ${MODE} | Base URL: ${BASE}`);
  console.log(`Scenarios: ${Object.keys(options.scenarios).join(', ')}`);
}

// --- Scenario functions ---

export function mapSites() {
  const { lat, lng } = randomMacedoniaCoords();
  const url = `${BASE}/sites/map?lat=${lat}&lng=${lng}&radiusKm=40&limit=200&detail=lite&zoom=11`;
  const res = http.get(url, { tags: { name: 'map_sites' } });
  check(res, { 'map_sites 2xx': (r) => r.status >= 200 && r.status < 300 });
  sleep(0.3);
}

export function mapClusters() {
  const c = randomMacedoniaCoords();
  const delta = 0.3;
  const params = [
    `minLat=${(c.lat - delta).toFixed(5)}`,
    `maxLat=${(c.lat + delta).toFixed(5)}`,
    `minLng=${(c.lng - delta).toFixed(5)}`,
    `maxLng=${(c.lng + delta).toFixed(5)}`,
    'zoom=10',
    'limit=400',
  ].join('&');
  const url = `${BASE}/sites/map/clusters?${params}`;
  const res = http.get(url, { tags: { name: 'map_clusters' } });
  check(res, { 'map_clusters 2xx': (r) => r.status >= 200 && r.status < 300 });
  sleep(0.3);
}

export function mapHeatmap() {
  const c = randomMacedoniaCoords();
  const delta = 0.5;
  const params = [
    `minLat=${(c.lat - delta).toFixed(5)}`,
    `maxLat=${(c.lat + delta).toFixed(5)}`,
    `minLng=${(c.lng - delta).toFixed(5)}`,
    `maxLng=${(c.lng + delta).toFixed(5)}`,
    'zoom=8',
    'limit=1200',
  ].join('&');
  const url = `${BASE}/sites/map/heatmap?${params}`;
  const res = http.get(url, { tags: { name: 'map_heatmap' } });
  check(res, { 'map_heatmap 2xx': (r) => r.status >= 200 && r.status < 300 });
  sleep(0.5);
}

export function mapMvt() {
  const z = 8 + Math.floor(Math.random() * 7); // z 8-14
  const { x, y } = randomMacedoniaTile(z);
  const url = `${BASE}/sites/map/tiles/${z}/${x}/${y}.mvt`;
  const res = http.get(url, { tags: { name: 'map_mvt' } });
  check(res, { 'map_mvt 2xx': (r) => r.status >= 200 && r.status < 300 });
  sleep(0.2);
}

export function mapSearch() {
  const payload = JSON.stringify({ query: randomSearchQuery() });
  const params = { headers: { 'Content-Type': 'application/json' }, tags: { name: 'map_search' } };
  const res = http.post(`${BASE}/sites/search`, payload, params);
  check(res, { 'map_search 2xx': (r) => r.status >= 200 && r.status < 300 });
  sleep(0.4);
}

export function mapSse() {
  const res = http.get(`${BASE}/sites/events`, {
    tags: { name: 'map_sse' },
    timeout: '6s',
  });
  check(res, { 'map_sse connected': (r) => r.status >= 200 && r.status < 300 });
  sleep(5);
}
