/**
 * k6 smoke: health, **readiness** (`GET /health/ready` — same path as blackbox `chisto_api_health_ready`),
 * feed, map, and reports paths with scenario tags so `scripts/check-k6-baseline.mjs` can compare against
 * `perf/baseline-thresholds.json`.
 *
 * Run: API_BASE_URL=http://127.0.0.1:3000 k6 run perf/smoke.js
 * Optional: AUTH_TOKEN — Bearer for GET /reports/me (otherwise 401 is OK for latency sample).
 */
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 2,
      duration: '20s',
      exec: 'smoke',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<600'],
    'http_req_duration{scenario:health}': ['p(95)<200'],
    'http_req_duration{scenario:readiness}': ['p(95)<300'],
    'http_req_duration{scenario:feed}': ['p(95)<400'],
    'http_req_duration{scenario:map}': ['p(95)<400'],
    'http_req_duration{scenario:reports}': ['p(95)<600'],
  },
};

const BASE = (__ENV.API_BASE_URL || 'http://127.0.0.1:3000').replace(/\/$/, '');

const TILES = [
  { z: 10, x: 572, y: 383 },
  { z: 8, x: 143, y: 95 },
];

function authHeaders() {
  const token = __ENV.AUTH_TOKEN || '';
  const headers = { 'Content-Type': 'application/json' };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

export function smoke() {
  const healthRes = http.get(`${BASE}/health`, { tags: { scenario: 'health' } });
  check(healthRes, { 'health 2xx': (r) => r.status >= 200 && r.status < 300 });

  const readyRes = http.get(`${BASE}/health/ready`, { tags: { scenario: 'readiness' } });
  check(readyRes, {
    'readiness 200': (r) => r.status === 200,
    'readiness body': (r) => typeof r.body === 'string' && r.body.includes('"status":"ok"'),
  });

  const feedRes = http.get(`${BASE}/sites?page=1&limit=10`, {
    headers: authHeaders(),
    tags: { scenario: 'feed' },
  });
  check(feedRes, { 'feed 2xx': (r) => r.status >= 200 && r.status < 300 });

  const tile = TILES[Math.floor(Math.random() * TILES.length)];
  const mapRes = http.get(`${BASE}/sites/map/tiles/${tile.z}/${tile.x}/${tile.y}`, {
    headers: authHeaders(),
    tags: { scenario: 'map' },
  });
  check(mapRes, { 'map 2xx': (r) => r.status >= 200 && r.status < 300 });

  const reportsRes = http.get(`${BASE}/reports/me?page=1&limit=5`, {
    headers: authHeaders(),
    tags: { scenario: 'reports' },
  });
  check(reportsRes, {
    'reports expected': (r) =>
      r.status === 401 || r.status === 403 || (r.status >= 200 && r.status < 300),
  });
}
