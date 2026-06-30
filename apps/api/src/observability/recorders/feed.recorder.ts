import { p95Ms, trimRollingBuffer } from './percentile.util';

let feedRequestsTotal = 0;
let feedCacheHits = 0;
let feedDurationsMs: number[] = [];
let feedCandidatePoolSizes: number[] = [];
const feedFeedbackCounts: Record<string, number> = {};
const feedCacheInvalidationCounts: Record<string, number> = {};
let feedCacheEntries = 0;
const feedReasonCodeCounts: Record<string, number> = {};
let feedPaginationContinuityIssues = 0;
let feedV2Requests = 0;
let feedV2Fallbacks = 0;
const feedV2StageLatenciesMs: Record<string, number[]> = {};
let feedV2ModelVersion = 'unknown';
let feedV2RankerMode = 'rules_fallback';
let feedV2ShadowComparisons = 0;
let feedV2ShadowTop10OverlapSum = 0;
let feedV2ShadowAvgAbsDeltaSum = 0;

export function recordFeedRequest(input: {
  durationMs: number;
  candidatePoolSize: number;
  cacheHit: boolean;
}): void {
  feedRequestsTotal += 1;
  if (input.cacheHit) feedCacheHits += 1;
  feedDurationsMs.push(input.durationMs);
  feedCandidatePoolSizes.push(input.candidatePoolSize);
  feedDurationsMs = trimRollingBuffer(feedDurationsMs);
  feedCandidatePoolSizes = trimRollingBuffer(feedCandidatePoolSizes);
}

export function recordFeedFeedback(feedbackType: string): void {
  const key = feedbackType || 'unknown';
  feedFeedbackCounts[key] = (feedFeedbackCounts[key] ?? 0) + 1;
}

export function recordFeedCacheInvalidation(reason: string): void {
  const key = reason || 'unknown';
  feedCacheInvalidationCounts[key] = (feedCacheInvalidationCounts[key] ?? 0) + 1;
}

export function setFeedCacheEntries(size: number): void {
  feedCacheEntries = Math.max(0, size);
}

export function recordFeedReasonCodes(reasonCodes: string[]): void {
  for (const reason of reasonCodes) {
    const key = reason || 'unknown';
    feedReasonCodeCounts[key] = (feedReasonCodeCounts[key] ?? 0) + 1;
  }
}

export function recordFeedPaginationContinuityIssue(): void {
  feedPaginationContinuityIssues += 1;
}

export function recordFeedV2Request(fallback: boolean): void {
  feedV2Requests += 1;
  if (fallback) feedV2Fallbacks += 1;
}

export function recordFeedV2StageLatency(stage: string, durationMs: number): void {
  const bucket = feedV2StageLatenciesMs[stage] ?? [];
  bucket.push(durationMs);
  feedV2StageLatenciesMs[stage] = bucket.length > 1200 ? bucket.slice(-1200) : bucket;
}

export function setFeedV2ModelVersion(version: string): void {
  feedV2ModelVersion = version;
}

export function setFeedV2RankerMode(mode: string): void {
  feedV2RankerMode = mode || 'unknown';
}

export function recordFeedV2ShadowComparison(input: { top10Overlap: number; avgAbsDelta: number }): void {
  feedV2ShadowComparisons += 1;
  feedV2ShadowTop10OverlapSum += Math.max(0, input.top10Overlap);
  feedV2ShadowAvgAbsDeltaSum += Math.max(0, input.avgAbsDelta);
}

export function snapshot() {
  return {
    feedRequestsTotal,
    feedCacheHits,
    feedCacheHitRate:
      feedRequestsTotal > 0 ? Number((feedCacheHits / feedRequestsTotal).toFixed(4)) : 0,
    feedP95Ms: p95Ms(feedDurationsMs),
    feedDurationBuckets: {
      le100: feedDurationsMs.filter((ms) => ms <= 100).length,
      le250: feedDurationsMs.filter((ms) => ms <= 250).length,
      le500: feedDurationsMs.filter((ms) => ms <= 500).length,
      le1000: feedDurationsMs.filter((ms) => ms <= 1000).length,
      gt1000: feedDurationsMs.filter((ms) => ms > 1000).length,
    },
    feedAvgCandidatePoolSize:
      feedCandidatePoolSizes.length > 0
        ? Number(
            (
              feedCandidatePoolSizes.reduce((acc, v) => acc + v, 0) / feedCandidatePoolSizes.length
            ).toFixed(2),
          )
        : 0,
    feedFeedbackCounts,
    feedCacheInvalidationCounts,
    feedCacheEntries,
    feedReasonCodeCounts,
    feedPaginationContinuityIssues,
    feedV2Requests,
    feedV2Fallbacks,
    feedV2ModelVersion,
    feedV2RankerMode,
    feedV2ShadowComparisons,
    feedV2ShadowTop10OverlapAvg:
      feedV2ShadowComparisons > 0
        ? Number((feedV2ShadowTop10OverlapSum / feedV2ShadowComparisons).toFixed(4))
        : 0,
    feedV2ShadowAvgAbsDelta:
      feedV2ShadowComparisons > 0
        ? Number((feedV2ShadowAvgAbsDeltaSum / feedV2ShadowComparisons).toFixed(4))
        : 0,
    feedV2StageP95Ms: Object.fromEntries(
      Object.entries(feedV2StageLatenciesMs).map(([stage, values]) => [stage, p95Ms(values)]),
    ),
  };
}
