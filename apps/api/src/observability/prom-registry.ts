import {
  Counter,
  Gauge,
  Histogram,
  Registry,
  collectDefaultMetrics,
} from 'prom-client';

/** Single Prometheus registry for scrape-based metrics (replaces Pushgateway path). */
export const promRegistry = new Registry();

collectDefaultMetrics({ register: promRegistry, prefix: 'chisto_' });

export const httpRequestsTotal = new Counter({
  name: 'chisto_http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'] as const,
  registers: [promRegistry],
});

export const httpRequestDurationMs = new Histogram({
  name: 'chisto_http_request_duration_ms',
  help: 'HTTP request duration in milliseconds',
  labelNames: ['method', 'route', 'status'] as const,
  buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000, 10000],
  registers: [promRegistry],
});

export const httpRequestsFailedTotal = new Counter({
  name: 'chisto_http_requests_failed_total',
  help: 'Total HTTP 5xx responses',
  labelNames: ['method', 'route'] as const,
  registers: [promRegistry],
});

export const auditWriteFailedTotal = new Counter({
  name: 'chisto_audit_write_failed_total',
  help: 'Audit log persistence failures',
  labelNames: ['action'] as const,
  registers: [promRegistry],
});

/** Legacy snapshot gauges bridged from ObservabilityStore until full migration. */
export const legacySnapshotGauges = {
  requestsTotal: new Gauge({
    name: 'chisto_requests_total',
    help: 'Legacy in-process request counter (snapshot)',
    registers: [promRegistry],
  }),
  requestsFailed: new Gauge({
    name: 'chisto_requests_failed_total',
    help: 'Legacy in-process 5xx counter (snapshot)',
    registers: [promRegistry],
  }),
  requestDurationP95Ms: new Gauge({
    name: 'chisto_request_duration_p95_ms',
    help: 'Legacy p95 request duration ms (snapshot)',
    registers: [promRegistry],
  }),
  pushDeadLetter: new Gauge({
    name: 'chisto_push_dead_letter_total',
    help: 'Push outbox permanently failed rows',
    registers: [promRegistry],
  }),
  mapOutboxFailed: new Gauge({
    name: 'chisto_map_outbox_failed_total',
    help: 'Map outbox dispatch failures',
    registers: [promRegistry],
  }),
  reportSideEffectFailed: new Gauge({
    name: 'chisto_report_side_effect_failed_total',
    help: 'Report side effects marked permanently failed',
    registers: [promRegistry],
  }),
  accountErasurePurged: new Counter({
    name: 'chisto_account_erasure_purged_total',
    help: 'Users hard-deleted after 30-day erasure grace',
    registers: [promRegistry],
  }),
  feedCacheL1Hits: new Counter({
    name: 'chisto_feed_cache_l1_hits_total',
    help: 'Feed in-memory L1 cache hits',
    registers: [promRegistry],
  }),
  feedCacheL2Hits: new Counter({
    name: 'chisto_feed_cache_l2_hits_total',
    help: 'Feed Redis L2 cache hits',
    registers: [promRegistry],
  }),
  feedCacheMisses: new Counter({
    name: 'chisto_feed_cache_misses_total',
    help: 'Feed cache misses',
    registers: [promRegistry],
  }),
};

export function normalizeRouteForMetrics(url: string): string {
  const path = (url.split('?')[0] ?? '/').replace(/\/+$/, '') || '/';
  return path
    .replace(/\/[a-z0-9]{20,30}/gi, '/:id')
    .replace(/\/\d+/g, '/:n');
}

export async function renderPrometheusMetrics(): Promise<string> {
  return promRegistry.metrics();
}
