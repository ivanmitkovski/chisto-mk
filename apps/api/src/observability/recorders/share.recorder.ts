import { p95Ms, trimRollingBuffer } from './percentile.util';

let shareLinksIssuedTotal = 0;
let shareEventsIngestedTotal = 0;
let shareEventsCountedTotal = 0;
let shareEventsDedupedTotal = 0;
let shareEventsInvalidTotal = 0;
let shareEventsRateLimitedTotal = 0;
let shareIssueDurationsMs: number[] = [];
let shareIngestDurationsMs: number[] = [];

export function recordShareLinkIssued(durationMs: number): void {
  shareLinksIssuedTotal += 1;
  shareIssueDurationsMs.push(durationMs);
  shareIssueDurationsMs = trimRollingBuffer(shareIssueDurationsMs);
}

export function recordShareAttributionEvent(input: {
  durationMs: number;
  counted: boolean;
  deduped: boolean;
  invalid: boolean;
  rateLimited: boolean;
}): void {
  shareEventsIngestedTotal += 1;
  if (input.counted) shareEventsCountedTotal += 1;
  if (input.deduped) shareEventsDedupedTotal += 1;
  if (input.invalid) shareEventsInvalidTotal += 1;
  if (input.rateLimited) shareEventsRateLimitedTotal += 1;
  shareIngestDurationsMs.push(input.durationMs);
  shareIngestDurationsMs = trimRollingBuffer(shareIngestDurationsMs);
}

export function snapshot() {
  return {
    shareLinksIssuedTotal,
    shareEventsIngestedTotal,
    shareEventsCountedTotal,
    shareEventsDedupedTotal,
    shareEventsInvalidTotal,
    shareEventsRateLimitedTotal,
    shareIssueP95Ms: p95Ms(shareIssueDurationsMs),
    shareIngestP95Ms: p95Ms(shareIngestDurationsMs),
  };
}
