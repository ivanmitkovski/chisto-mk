/**
 * k6 load test suite for Chisto.mk API.
 * Run: API_BASE_URL=http://127.0.0.1:3000 k6 run perf/k6-load-test.js
 * Requires k6: https://k6.io/docs/get-started/installation/
 *
 * Optional env vars:
 *   AUTH_TOKEN — Bearer token for authenticated endpoints
 *   API_BASE_URL — defaults to http://127.0.0.1:3000
 */
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const feedLatency = new Trend('feed_latency', true);
const mapLatency = new Trend('map_latency', true);

const BASE = (__ENV.API_BASE_URL || 'http://127.0.0.1:3000').replace(/\/$/, '');
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';

export const options = {
  scenarios: {
    health_baseline: {
      executor: 'constant-vus',
      vus: 5,
      duration: '30s',
      exec: 'healthCheck',
      tags: { scenario: 'health' },
    },
    feed_read_heavy: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '15s', target: 20 },
        { duration: '30s', target: 20 },
        { duration: '10s', target: 0 },
      ],
      exec: 'feedRead',
      tags: { scenario: 'feed' },
    },
    map_tiles: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '15s', target: 10 },
        { duration: '30s', target: 10 },
        { duration: '10s', target: 0 },
      ],
      exec: 'mapTiles',
      tags: { scenario: 'map' },
    },
    report_submission: {
      executor: 'per-vu-iterations',
      vus: 5,
      iterations: 10,
      exec: 'reportSubmit',
      tags: { scenario: 'reports' },
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    'http_req_duration{scenario:health}': ['p(95)<100'],
    'http_req_duration{scenario:feed}': ['p(95)<300'],
    'http_req_duration{scenario:map}': ['p(95)<300'],
    'http_req_duration{scenario:reports}': ['p(95)<500'],
    errors: ['rate<0.01'],
    feed_latency: ['p(95)<300'],
    map_latency: ['p(95)<300'],
  },
};

function authHeaders() {
  const headers = { 'Content-Type': 'application/json' };
  if (AUTH_TOKEN) {
    headers['Authorization'] = `Bearer ${AUTH_TOKEN}`;
  }
  return headers;
}

export function healthCheck() {
  group('Health', () => {
    const res = http.get(`${BASE}/health`);
    const ok = check(res, {
      'health status 200': (r) => r.status === 200,
      'body has status ok': (r) => {
        try {
          return JSON.parse(r.body).status === 'ok';
        } catch {
          return false;
        }
      },
    });
    errorRate.add(!ok);
  });
  sleep(0.5);
}

export function feedRead() {
  group('Sites Feed', () => {
    const res = http.get(`${BASE}/sites?page=1&limit=20`, {
      headers: authHeaders(),
    });
    const ok = check(res, {
      'feed status 2xx': (r) => r.status >= 200 && r.status < 300,
    });
    feedLatency.add(res.timings.duration);
    errorRate.add(!ok);
  });
  sleep(1);
}

export function mapTiles() {
  const testTiles = [
    { z: 10, x: 572, y: 383 },
    { z: 12, x: 2290, y: 1534 },
    { z: 8, x: 143, y: 95 },
  ];
  group('Map Tiles', () => {
    const tile = testTiles[Math.floor(Math.random() * testTiles.length)];
    const res = http.get(
      `${BASE}/sites/map/tiles/${tile.z}/${tile.x}/${tile.y}`,
      { headers: authHeaders() },
    );
    const ok = check(res, {
      'tile status 2xx or 204': (r) => r.status >= 200 && r.status < 300,
    });
    mapLatency.add(res.timings.duration);
    errorRate.add(!ok);
  });
  sleep(0.5);
}

export function reportSubmit() {
  if (!AUTH_TOKEN) {
    sleep(1);
    return;
  }
  group('Report Submit', () => {
    const payload = JSON.stringify({
      latitude: 41.9973 + Math.random() * 0.01,
      longitude: 21.428 + Math.random() * 0.01,
      description: `k6 load test report ${Date.now()}`,
      category: 'ILLEGAL_DUMP',
    });
    const res = http.post(`${BASE}/reports`, payload, {
      headers: authHeaders(),
    });
    const ok = check(res, {
      'submit status 2xx': (r) => r.status >= 200 && r.status < 300,
    });
    errorRate.add(!ok);
  });
  sleep(2);
}
