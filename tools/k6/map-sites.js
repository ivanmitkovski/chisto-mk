/**
 * Load test for public GET /sites/map (no auth).
 *
 * Usage:
 *   k6 run tools/k6/map-sites.js -e BASE_URL=https://api.example.com
 *
 * Optional: -e VUS=30 -e DURATION=60s
 * SSE (/sites/events) needs JWT; exercise separately with k6 websockets or manual scripts.
 */

import http from 'k6/http';
import { check, sleep } from 'k6';

const base = __ENV.BASE_URL || 'http://localhost:3000';
const vus = Number(__ENV.VUS || 20);
const duration = __ENV.DURATION || '45s';

export const options = {
  vus,
  duration,
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<3000'],
  },
};

export default function () {
  const q =
    'lat=41.6086&lng=21.7453&radiusKm=80&limit=200&minLat=41.4&maxLat=41.8&minLng=21.5&maxLng=22.0';
  const res = http.get(`${base.replace(/\/$/, '')}/sites/map?${q}`);
  check(res, {
    'status 200': (r) => r.status === 200,
    'has data array': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body.data);
      } catch {
        return false;
      }
    },
  });
  sleep(0.3);
}
