import { percentileFromSorted, trimRollingBuffer } from './percentile.util';

let requestsTotal = 0;
let requestsFailed = 0;
let requestDurationsMs: number[] = [];

export function recordRequest(durationMs: number, statusCode: number): void {
  requestsTotal += 1;
  if (statusCode >= 500) {
    requestsFailed += 1;
  }
  requestDurationsMs.push(durationMs);
  requestDurationsMs = trimRollingBuffer(requestDurationsMs);
}

export function snapshot() {
  const sorted = [...requestDurationsMs].sort((a, b) => a - b);
  return {
    requestsTotal,
    requestsFailed,
    p50Ms: percentileFromSorted(sorted, 50),
    p95Ms: percentileFromSorted(sorted, 95),
    p99Ms: percentileFromSorted(sorted, 99),
  };
}

export function resetForTests(): void {
  requestsTotal = 0;
  requestsFailed = 0;
  requestDurationsMs = [];
}
