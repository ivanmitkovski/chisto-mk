const PUSH_GATEWAY_URL = process.env.METRICS_PUSH_GATEWAY_URL?.trim() || null;
const PUSH_INTERVAL_MS = 15_000;
const JOB_NAME = 'chisto_api';

export class ObservabilityStore {
  private static pushIntervalHandle: ReturnType<typeof setInterval> | null = null;

  static startPushGatewayLoop(): void {
    if (!PUSH_GATEWAY_URL || this.pushIntervalHandle) return;
    this.pushIntervalHandle = setInterval(() => {
      this.pushToGateway().catch(() => {});
    }, PUSH_INTERVAL_MS);
    if (typeof this.pushIntervalHandle === 'object' && 'unref' in this.pushIntervalHandle) {
      this.pushIntervalHandle.unref();
    }
  }

  static stopPushGatewayLoop(): void {
    if (this.pushIntervalHandle) {
      clearInterval(this.pushIntervalHandle);
      this.pushIntervalHandle = null;
    }
  }

  private static async pushToGateway(): Promise<void> {
    if (!PUSH_GATEWAY_URL) return;
    const snap = this.snapshot();
    const lines: string[] = [];
    const g = (name: string, value: number, help?: string) => {
      if (help) lines.push(`# HELP ${name} ${help}`);
      lines.push(`# TYPE ${name} gauge`);
      lines.push(`${name} ${value}`);
    };
    g('chisto_requests_total', snap.requestsTotal, 'Total HTTP requests');
    g('chisto_requests_failed_total', snap.requestsFailed, 'Total 5xx responses');
    g('chisto_request_duration_p95_ms', snap.p95Ms, 'p95 request duration');
    g('chisto_feed_requests_total', snap.feedRequestsTotal, 'Total feed requests');
    g('chisto_feed_cache_hit_rate', snap.feedCacheHitRate, 'Feed cache hit ratio');
    g('chisto_feed_duration_p95_ms', snap.feedP95Ms, 'p95 feed duration');
    g('chisto_map_requests_total', snap.mapRequestsTotal, 'Total map requests');
    g('chisto_map_cache_hit_rate', snap.mapCacheHitRate, 'Map cache hit ratio');
    g('chisto_map_duration_p95_ms', snap.mapP95Ms, 'p95 map duration');
    g('chisto_push_sends_total', snap.pushSendsTotal, 'Total push notifications');
    g('chisto_push_sends_failure', snap.pushSendsFailure, 'Failed push notifications');
    g('chisto_push_queue_depth', snap.pushQueueDepth, 'Push queue depth');
    g('chisto_reports_submit_success', snap.reportsSubmitSuccess, 'Successful report submissions');
    g('chisto_reports_submit_error', snap.reportsSubmitError, 'Failed report submissions');
    g('chisto_map_outbox_pending', snap.mapOutboxPending, 'MapEventOutbox rows in PENDING status (last sampled)');

    lines.push('# HELP chisto_prisma_p1008_total Public API responses mapped from Prisma P1008 timeouts');
    lines.push('# TYPE chisto_prisma_p1008_total counter');
    lines.push(`chisto_prisma_p1008_total ${this.prismaP1008Total}`);
    const body = lines.join('\n') + '\n';
    const url = `${PUSH_GATEWAY_URL}/metrics/job/${JOB_NAME}`;
    try {
      await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'text/plain; version=0.0.4' },
        body,
        signal: AbortSignal.timeout(5_000),
      });
    } catch {
      // Silently ignore push failures to avoid cascading alerts
    }
  }

  private static requestsTotal = 0;
  private static requestsFailed = 0;
  private static requestDurationsMs: number[] = [];
  private static feedRequestsTotal = 0;
  private static feedCacheHits = 0;
  private static feedDurationsMs: number[] = [];
  private static feedCandidatePoolSizes: number[] = [];
  private static feedFeedbackCounts: Record<string, number> = {};
  private static feedCacheInvalidationCounts: Record<string, number> = {};
  private static feedCacheEntries = 0;
  private static feedReasonCodeCounts: Record<string, number> = {};
  private static feedPaginationContinuityIssues = 0;
  private static feedV2Requests = 0;
  private static feedV2Fallbacks = 0;
  private static feedV2StageLatenciesMs: Record<string, number[]> = {};
  private static feedV2ModelVersion = 'unknown';
  private static feedV2RankerMode = 'rules_fallback';
  private static feedV2ShadowComparisons = 0;
  private static feedV2ShadowTop10OverlapSum = 0;
  private static feedV2ShadowAvgAbsDeltaSum = 0;
  private static pushSendsTotal = 0;
  private static pushSendsSuccess = 0;
  private static pushSendsFailure = 0;
  private static pushSendsRevoked = 0;
  private static pushTokenRevocations = 0;
  private static pushQueueRetries = 0;
  private static pushInboxReads = 0;
  private static pushQueueDepth = 0;
  private static pushActiveLeases = 0;
  private static pushDeadLetterCount = 0;
  private static mapRequestsTotal = 0;
  private static mapCacheHits = 0;
  private static mapCacheInvalidationCounts: Record<string, number> = {};
  private static mapFallbackResponses = 0;
  private static mapDurationsMs: number[] = [];
  private static mapCandidatePoolSizes: number[] = [];
  private static mapSseConnectionsTotal = 0;
  private static mapSseConnectionsActive = 0;
  private static mapSseReconnectHints = 0;
  private static mapSseEventsEmitted = 0;
  private static mapSseReplayEvents = 0;
  private static mapCacheEntries = 0;
  private static mapOutboxDispatched = 0;
  private static mapOutboxFailed = 0;
  private static mapOutboxLagMs = 0;
  private static mapProjectionRowsTotal = 0;
  private static mapProjectionHotRows = 0;
  private static mapProjectionStalenessSeconds = 0;
  private static mapColdSitesArchivedTotal = 0;
  private static mapOutboxRowsPurgedTotal = 0;
  private static mapOutboxPendingGauge = 0;
  private static prismaP1008Total = 0;
  private static mapZoomTierRequests: Record<string, number> = {};
  /** `${mode}:${zoomBucket}` -> recent durations for p95 slicing */
  private static mapDurationByModeZoom: Record<string, number[]> = {};
  private static mapRequestsByMode: Record<string, number> = {};
  private static mapCacheHitsByMode: Record<string, number> = {};
  private static mapQueryRowCounts: number[] = [];
  private static cleanupEventStaffPendingSignals = 0;
  private static cleanupEventPublishedAudienceNotified = 0;
  private static cleanupEventModerationApproved = 0;
  private static impactReceiptFetchTotal = 0;
  private static shareLinksIssuedTotal = 0;
  private static shareEventsIngestedTotal = 0;
  private static shareEventsCountedTotal = 0;
  private static shareEventsDedupedTotal = 0;
  private static shareEventsInvalidTotal = 0;
  private static shareEventsRateLimitedTotal = 0;
  private static shareIssueDurationsMs: number[] = [];
  private static shareIngestDurationsMs: number[] = [];
  private static reportsSubmitSuccess = 0;
  private static reportsSubmitError = 0;
  private static reportsUploadSuccess = 0;
  private static reportsUploadError = 0;
  private static reportsSignedUrlIssued = 0;
  private static reportsSignedUrlCacheHit = 0;
  private static reportsSignedUrlError = 0;
  private static reportsSubmitDurationsMs: number[] = [];
  private static reportsSignedUrlLatencyMs: number[] = [];
  private static reportsSubmitPointsAwardedTotal = 0;
  private static reportApprovalPointsAwardedTotal = 0;
  private static reportApprovalPointsCappedTotal = 0;
  private static reportApprovalPointsRevokedTotal = 0;

  static recordReportSubmitPointsAwarded(delta: number): void {
    if (delta > 0) {
      this.reportsSubmitPointsAwardedTotal += delta;
    }
  }

  static recordReportApprovalPointsAwarded(delta: number): void {
    if (delta > 0) {
      this.reportApprovalPointsAwardedTotal += delta;
    }
  }

  static recordReportApprovalPointsCapped(): void {
    this.reportApprovalPointsCappedTotal += 1;
  }

  static recordReportApprovalPointsRevoked(amount: number): void {
    if (amount > 0) {
      this.reportApprovalPointsRevokedTotal += amount;
    }
  }

  static recordReportSubmit(outcome: 'success' | 'error', durationMs?: number): void {
    if (outcome === 'success') {
      this.reportsSubmitSuccess += 1;
    } else {
      this.reportsSubmitError += 1;
    }
    if (durationMs != null && durationMs >= 0) {
      this.reportsSubmitDurationsMs.push(durationMs);
      if (this.reportsSubmitDurationsMs.length > 2000) {
        this.reportsSubmitDurationsMs = this.reportsSubmitDurationsMs.slice(-1200);
      }
    }
  }

  static recordReportUpload(outcome: 'success' | 'error'): void {
    if (outcome === 'success') {
      this.reportsUploadSuccess += 1;
    } else {
      this.reportsUploadError += 1;
    }
  }

  static recordReportSignedUrl(outcome: 'issued' | 'cache_hit' | 'error'): void {
    if (outcome === 'issued') {
      this.reportsSignedUrlIssued += 1;
    } else if (outcome === 'cache_hit') {
      this.reportsSignedUrlCacheHit += 1;
    } else {
      this.reportsSignedUrlError += 1;
    }
  }

  static recordReportSignedUrlLatencyMs(durationMs: number): void {
    if (durationMs < 0) {
      return;
    }
    this.reportsSignedUrlLatencyMs.push(durationMs);
    if (this.reportsSignedUrlLatencyMs.length > 2000) {
      this.reportsSignedUrlLatencyMs = this.reportsSignedUrlLatencyMs.slice(-1200);
    }
  }

  static recordShareLinkIssued(durationMs: number): void {
    this.shareLinksIssuedTotal += 1;
    this.shareIssueDurationsMs.push(durationMs);
    if (this.shareIssueDurationsMs.length > 2000) {
      this.shareIssueDurationsMs = this.shareIssueDurationsMs.slice(-1200);
    }
  }

  static recordShareAttributionEvent(input: {
    durationMs: number;
    counted: boolean;
    deduped: boolean;
    invalid: boolean;
    rateLimited: boolean;
  }): void {
    this.shareEventsIngestedTotal += 1;
    if (input.counted) this.shareEventsCountedTotal += 1;
    if (input.deduped) this.shareEventsDedupedTotal += 1;
    if (input.invalid) this.shareEventsInvalidTotal += 1;
    if (input.rateLimited) this.shareEventsRateLimitedTotal += 1;
    this.shareIngestDurationsMs.push(input.durationMs);
    if (this.shareIngestDurationsMs.length > 2000) {
      this.shareIngestDurationsMs = this.shareIngestDurationsMs.slice(-1200);
    }
  }

  static recordCleanupEventStaffPendingSignals(count: number): void {
    this.cleanupEventStaffPendingSignals += Math.max(0, count);
  }

  static recordCleanupEventPublishedAudienceBatch(count: number): void {
    this.cleanupEventPublishedAudienceNotified += Math.max(0, count);
  }

  static recordCleanupEventModerationApproved(): void {
    this.cleanupEventModerationApproved += 1;
  }

  static recordImpactReceiptFetch(): void {
    this.impactReceiptFetchTotal += 1;
  }

  static recordRequest(durationMs: number, statusCode: number): void {
    this.requestsTotal += 1;
    if (statusCode >= 500) {
      this.requestsFailed += 1;
    }
    this.requestDurationsMs.push(durationMs);
    if (this.requestDurationsMs.length > 2000) {
      this.requestDurationsMs = this.requestDurationsMs.slice(-1200);
    }
  }

  static recordFeedRequest(input: {
    durationMs: number;
    candidatePoolSize: number;
    cacheHit: boolean;
  }): void {
    this.feedRequestsTotal += 1;
    if (input.cacheHit) this.feedCacheHits += 1;
    this.feedDurationsMs.push(input.durationMs);
    this.feedCandidatePoolSizes.push(input.candidatePoolSize);
    if (this.feedDurationsMs.length > 2000) {
      this.feedDurationsMs = this.feedDurationsMs.slice(-1200);
    }
    if (this.feedCandidatePoolSizes.length > 2000) {
      this.feedCandidatePoolSizes = this.feedCandidatePoolSizes.slice(-1200);
    }
  }

  static recordFeedFeedback(feedbackType: string): void {
    const key = feedbackType || 'unknown';
    this.feedFeedbackCounts[key] = (this.feedFeedbackCounts[key] ?? 0) + 1;
  }

  static recordFeedCacheInvalidation(reason: string): void {
    const key = reason || 'unknown';
    this.feedCacheInvalidationCounts[key] = (this.feedCacheInvalidationCounts[key] ?? 0) + 1;
  }

  static setFeedCacheEntries(size: number): void {
    this.feedCacheEntries = Math.max(0, size);
  }

  static recordFeedReasonCodes(reasonCodes: string[]): void {
    for (const reason of reasonCodes) {
      const key = reason || 'unknown';
      this.feedReasonCodeCounts[key] = (this.feedReasonCodeCounts[key] ?? 0) + 1;
    }
  }

  static recordFeedPaginationContinuityIssue(): void {
    this.feedPaginationContinuityIssues += 1;
  }

  static recordFeedV2Request(fallback: boolean): void {
    this.feedV2Requests += 1;
    if (fallback) this.feedV2Fallbacks += 1;
  }

  static recordFeedV2StageLatency(stage: string, durationMs: number): void {
    const bucket = this.feedV2StageLatenciesMs[stage] ?? [];
    bucket.push(durationMs);
    this.feedV2StageLatenciesMs[stage] = bucket.length > 1200 ? bucket.slice(-1200) : bucket;
  }

  static setFeedV2ModelVersion(version: string): void {
    this.feedV2ModelVersion = version;
  }

  static setFeedV2RankerMode(mode: string): void {
    this.feedV2RankerMode = mode || 'unknown';
  }

  static recordFeedV2ShadowComparison(input: { top10Overlap: number; avgAbsDelta: number }): void {
    this.feedV2ShadowComparisons += 1;
    this.feedV2ShadowTop10OverlapSum += Math.max(0, input.top10Overlap);
    this.feedV2ShadowAvgAbsDeltaSum += Math.max(0, input.avgAbsDelta);
  }

  static recordPushSend(outcome: 'success' | 'failure' | 'revoked'): void {
    this.pushSendsTotal += 1;
    if (outcome === 'success') this.pushSendsSuccess += 1;
    else if (outcome === 'failure') this.pushSendsFailure += 1;
    else if (outcome === 'revoked') this.pushSendsRevoked += 1;
  }

  static recordPushTokenRevocation(): void {
    this.pushTokenRevocations += 1;
  }

  static recordPushQueueRetry(): void {
    this.pushQueueRetries += 1;
  }

  static recordPushInboxRead(): void {
    this.pushInboxReads += 1;
  }

  static recordMapRequest(input: {
    durationMs: number;
    candidatePoolSize: number;
    cacheHit: boolean;
    servedFromFallback?: boolean;
    mode?: 'sites' | 'clusters' | 'heatmap';
    zoomBucket?: 'z_le_8' | 'z_9_12' | 'z_ge_13';
  }): void {
    this.mapRequestsTotal += 1;
    if (input.cacheHit) this.mapCacheHits += 1;
    if (input.servedFromFallback) this.mapFallbackResponses += 1;
    this.mapDurationsMs.push(input.durationMs);
    this.mapCandidatePoolSizes.push(input.candidatePoolSize);
    if (this.mapDurationsMs.length > 2000) {
      this.mapDurationsMs = this.mapDurationsMs.slice(-1200);
    }
    if (this.mapCandidatePoolSizes.length > 2000) {
      this.mapCandidatePoolSizes = this.mapCandidatePoolSizes.slice(-1200);
    }
    const mode = input.mode ?? 'sites';
    const bucket = input.zoomBucket ?? 'z_9_12';
    const sliceKey = `${mode}:${bucket}`;
    this.mapRequestsByMode[sliceKey] = (this.mapRequestsByMode[sliceKey] ?? 0) + 1;
    if (input.cacheHit) {
      this.mapCacheHitsByMode[sliceKey] = (this.mapCacheHitsByMode[sliceKey] ?? 0) + 1;
    }
    const slice = this.mapDurationByModeZoom[sliceKey] ?? [];
    slice.push(input.durationMs);
    this.mapDurationByModeZoom[sliceKey] =
      slice.length > 800 ? slice.slice(-500) : slice;
  }

  static recordMapSseConnected(): void {
    this.mapSseConnectionsTotal += 1;
    this.mapSseConnectionsActive += 1;
  }

  static recordMapSseDisconnected(): void {
    this.mapSseConnectionsActive = Math.max(0, this.mapSseConnectionsActive - 1);
  }

  static recordMapSseReconnectHint(): void {
    this.mapSseReconnectHints += 1;
  }

  static recordMapSseEventEmitted(): void {
    this.mapSseEventsEmitted += 1;
  }

  static recordMapSseReplayEvents(count: number): void {
    this.mapSseReplayEvents += Math.max(0, count);
  }

  static setMapCacheEntries(size: number): void {
    this.mapCacheEntries = Math.max(0, size);
  }

  static recordMapCacheInvalidation(reason: string): void {
    const key = reason || 'unknown';
    this.mapCacheInvalidationCounts[key] =
      (this.mapCacheInvalidationCounts[key] ?? 0) + 1;
  }

  static recordMapOutboxDispatch(input: { failed: boolean; lagMs: number }): void {
    if (input.failed) {
      this.mapOutboxFailed += 1;
    } else {
      this.mapOutboxDispatched += 1;
    }
    this.mapOutboxLagMs = Math.max(0, input.lagMs);
  }

  static recordMapProjectionSnapshot(input: {
    rowsTotal: number;
    hotRows: number;
    stalenessSeconds: number;
  }): void {
    this.mapProjectionRowsTotal = Math.max(0, input.rowsTotal);
    this.mapProjectionHotRows = Math.max(0, input.hotRows);
    this.mapProjectionStalenessSeconds = Math.max(0, input.stalenessSeconds);
  }

  static recordMapProjectionHotRefresh(changedRows: number): void {
    this.mapColdSitesArchivedTotal += Math.max(0, changedRows);
  }

  static recordMapOutboxRowsPurged(count: number): void {
    this.mapOutboxRowsPurgedTotal += Math.max(0, count);
  }

  static setMapOutboxPendingCount(count: number): void {
    this.mapOutboxPendingGauge = Math.max(0, Math.floor(count));
  }

  /** Incremented when the API returns DATABASE_TIMEOUT for Prisma P1008 (see GlobalExceptionFilter). */
  static recordPrismaP1008Response(): void {
    this.prismaP1008Total += 1;
  }

  static recordMapZoomTierRequest(tier: 'low' | 'mid' | 'high'): void {
    this.mapZoomTierRequests[tier] = (this.mapZoomTierRequests[tier] ?? 0) + 1;
  }

  static recordMapQueryRowCount(count: number): void {
    this.mapQueryRowCounts.push(Math.max(0, count));
    if (this.mapQueryRowCounts.length > 2000) {
      this.mapQueryRowCounts = this.mapQueryRowCounts.slice(-1200);
    }
  }

  static setPushQueueStats(input: {
    queueDepth: number;
    activeLeases: number;
    deadLetterCount: number;
  }): void {
    this.pushQueueDepth = input.queueDepth;
    this.pushActiveLeases = input.activeLeases;
    this.pushDeadLetterCount = input.deadLetterCount;
  }

  static snapshot() {
    const sorted = [...this.requestDurationsMs].sort((a, b) => a - b);
    const p = (percentile: number) => {
      if (sorted.length === 0) return 0;
      const idx = Math.min(sorted.length - 1, Math.floor((percentile / 100) * sorted.length));
      return Number(sorted[idx].toFixed(2));
    };
    return {
      requestsTotal: this.requestsTotal,
      requestsFailed: this.requestsFailed,
      p50Ms: p(50),
      p95Ms: p(95),
      p99Ms: p(99),
      feedRequestsTotal: this.feedRequestsTotal,
      feedCacheHits: this.feedCacheHits,
      feedCacheHitRate:
        this.feedRequestsTotal > 0
          ? Number((this.feedCacheHits / this.feedRequestsTotal).toFixed(4))
          : 0,
      feedP95Ms: (() => {
        const fs = [...this.feedDurationsMs].sort((a, b) => a - b);
        if (fs.length === 0) return 0;
        const idx = Math.min(fs.length - 1, Math.floor(0.95 * fs.length));
        return Number(fs[idx].toFixed(2));
      })(),
      feedDurationBuckets: {
        le100:
          this.feedDurationsMs.filter((ms) => ms <= 100).length,
        le250:
          this.feedDurationsMs.filter((ms) => ms <= 250).length,
        le500:
          this.feedDurationsMs.filter((ms) => ms <= 500).length,
        le1000:
          this.feedDurationsMs.filter((ms) => ms <= 1000).length,
        gt1000:
          this.feedDurationsMs.filter((ms) => ms > 1000).length,
      },
      feedAvgCandidatePoolSize:
        this.feedCandidatePoolSizes.length > 0
          ? Number(
              (
                this.feedCandidatePoolSizes.reduce((acc, v) => acc + v, 0) /
                this.feedCandidatePoolSizes.length
              ).toFixed(2),
            )
          : 0,
      feedFeedbackCounts: this.feedFeedbackCounts,
      feedCacheInvalidationCounts: this.feedCacheInvalidationCounts,
      feedCacheEntries: this.feedCacheEntries,
      feedReasonCodeCounts: this.feedReasonCodeCounts,
      feedPaginationContinuityIssues: this.feedPaginationContinuityIssues,
      feedV2Requests: this.feedV2Requests,
      feedV2Fallbacks: this.feedV2Fallbacks,
      feedV2ModelVersion: this.feedV2ModelVersion,
      feedV2RankerMode: this.feedV2RankerMode,
      feedV2ShadowComparisons: this.feedV2ShadowComparisons,
      feedV2ShadowTop10OverlapAvg:
        this.feedV2ShadowComparisons > 0
          ? Number((this.feedV2ShadowTop10OverlapSum / this.feedV2ShadowComparisons).toFixed(4))
          : 0,
      feedV2ShadowAvgAbsDelta:
        this.feedV2ShadowComparisons > 0
          ? Number((this.feedV2ShadowAvgAbsDeltaSum / this.feedV2ShadowComparisons).toFixed(4))
          : 0,
      feedV2StageP95Ms: Object.fromEntries(
        Object.entries(this.feedV2StageLatenciesMs).map(([stage, values]) => {
          const sortedValues = [...values].sort((a, b) => a - b);
          if (sortedValues.length === 0) return [stage, 0];
          const idx = Math.min(sortedValues.length - 1, Math.floor(0.95 * sortedValues.length));
          return [stage, Number(sortedValues[idx].toFixed(2))];
        }),
      ),
      pushSendsTotal: this.pushSendsTotal,
      pushSendsSuccess: this.pushSendsSuccess,
      pushSendsFailure: this.pushSendsFailure,
      pushSendsRevoked: this.pushSendsRevoked,
      pushTokenRevocations: this.pushTokenRevocations,
      pushQueueRetries: this.pushQueueRetries,
      pushInboxReads: this.pushInboxReads,
      pushQueueDepth: this.pushQueueDepth,
      pushActiveLeases: this.pushActiveLeases,
      pushDeadLetterCount: this.pushDeadLetterCount,
      mapRequestsTotal: this.mapRequestsTotal,
      mapCacheHits: this.mapCacheHits,
      mapFallbackResponses: this.mapFallbackResponses,
      mapCacheHitRate:
        this.mapRequestsTotal > 0
          ? Number((this.mapCacheHits / this.mapRequestsTotal).toFixed(4))
          : 0,
      mapP95Ms: (() => {
        const ms = [...this.mapDurationsMs].sort((a, b) => a - b);
        if (ms.length === 0) return 0;
        const idx = Math.min(ms.length - 1, Math.floor(0.95 * ms.length));
        return Number(ms[idx].toFixed(2));
      })(),
      mapDurationBuckets: {
        le100: this.mapDurationsMs.filter((ms) => ms <= 100).length,
        le250: this.mapDurationsMs.filter((ms) => ms <= 250).length,
        le500: this.mapDurationsMs.filter((ms) => ms <= 500).length,
        le1000: this.mapDurationsMs.filter((ms) => ms <= 1000).length,
        gt1000: this.mapDurationsMs.filter((ms) => ms > 1000).length,
      },
      mapAvgCandidatePoolSize:
        this.mapCandidatePoolSizes.length > 0
          ? Number(
              (
                this.mapCandidatePoolSizes.reduce((acc, v) => acc + v, 0) /
                this.mapCandidatePoolSizes.length
              ).toFixed(2),
            )
          : 0,
      mapSseConnectionsTotal: this.mapSseConnectionsTotal,
      mapSseConnectionsActive: this.mapSseConnectionsActive,
      mapSseReconnectHints: this.mapSseReconnectHints,
      mapSseEventsEmitted: this.mapSseEventsEmitted,
      mapSseReplayEvents: this.mapSseReplayEvents,
      mapCacheEntries: this.mapCacheEntries,
      mapCacheInvalidationCounts: this.mapCacheInvalidationCounts,
      mapOutboxDispatched: this.mapOutboxDispatched,
      mapOutboxFailed: this.mapOutboxFailed,
      mapOutboxLagMs: this.mapOutboxLagMs,
      mapProjectionRowsTotal: this.mapProjectionRowsTotal,
      mapProjectionHotRows: this.mapProjectionHotRows,
      mapProjectionStalenessSeconds: this.mapProjectionStalenessSeconds,
      mapColdSitesArchivedTotal: this.mapColdSitesArchivedTotal,
      mapOutboxRowsPurgedTotal: this.mapOutboxRowsPurgedTotal,
      mapZoomTierRequests: this.mapZoomTierRequests,
      mapAvgQueryRowCount:
        this.mapQueryRowCounts.length > 0
          ? Number((this.mapQueryRowCounts.reduce((acc, v) => acc + v, 0) / this.mapQueryRowCounts.length).toFixed(2))
          : 0,
      mapRequestsByModeZoom: { ...this.mapRequestsByMode },
      mapCacheHitsByModeZoom: { ...this.mapCacheHitsByMode },
      mapModeZoomLatencyP95Ms: Object.fromEntries(
        Object.entries(this.mapDurationByModeZoom).map(([k, values]) => {
          const sorted = [...values].sort((a, b) => a - b);
          if (sorted.length === 0) return [k, 0];
          const idx = Math.min(sorted.length - 1, Math.floor(0.95 * sorted.length));
          return [k, Number(sorted[idx].toFixed(2))];
        }),
      ),
      cleanupEventStaffPendingSignals: this.cleanupEventStaffPendingSignals,
      cleanupEventPublishedAudienceNotified: this.cleanupEventPublishedAudienceNotified,
      cleanupEventModerationApproved: this.cleanupEventModerationApproved,
      impactReceiptFetchTotal: this.impactReceiptFetchTotal,
      shareLinksIssuedTotal: this.shareLinksIssuedTotal,
      shareEventsIngestedTotal: this.shareEventsIngestedTotal,
      shareEventsCountedTotal: this.shareEventsCountedTotal,
      shareEventsDedupedTotal: this.shareEventsDedupedTotal,
      shareEventsInvalidTotal: this.shareEventsInvalidTotal,
      shareEventsRateLimitedTotal: this.shareEventsRateLimitedTotal,
      shareIssueP95Ms: (() => {
        const ms = [...this.shareIssueDurationsMs].sort((a, b) => a - b);
        if (ms.length == 0) return 0;
        const idx = Math.min(ms.length - 1, Math.floor(0.95 * ms.length));
        return Number(ms[idx].toFixed(2));
      })(),
      shareIngestP95Ms: (() => {
        const ms = [...this.shareIngestDurationsMs].sort((a, b) => a - b);
        if (ms.length == 0) return 0;
        const idx = Math.min(ms.length - 1, Math.floor(0.95 * ms.length));
        return Number(ms[idx].toFixed(2));
      })(),
      reportsSubmitSuccess: this.reportsSubmitSuccess,
      reportsSubmitError: this.reportsSubmitError,
      reportsSubmitPointsAwardedTotal: this.reportsSubmitPointsAwardedTotal,
      reportApprovalPointsAwardedTotal: this.reportApprovalPointsAwardedTotal,
      reportApprovalPointsCappedTotal: this.reportApprovalPointsCappedTotal,
      reportApprovalPointsRevokedTotal: this.reportApprovalPointsRevokedTotal,
      reportsUploadSuccess: this.reportsUploadSuccess,
      reportsUploadError: this.reportsUploadError,
      reportsSignedUrlIssued: this.reportsSignedUrlIssued,
      reportsSignedUrlCacheHit: this.reportsSignedUrlCacheHit,
      reportsSignedUrlError: this.reportsSignedUrlError,
      reportsSubmitP95Ms: (() => {
        const ms = [...this.reportsSubmitDurationsMs].sort((a, b) => a - b);
        if (ms.length === 0) {
          return 0;
        }
        const idx = Math.min(ms.length - 1, Math.floor(0.95 * ms.length));
        return Number(ms[idx].toFixed(2));
      })(),
      reportsSignedUrlLatencyP95Ms: (() => {
        const ms = [...this.reportsSignedUrlLatencyMs].sort((a, b) => a - b);
        if (ms.length === 0) {
          return 0;
        }
        const idx = Math.min(ms.length - 1, Math.floor(0.95 * ms.length));
        return Number(ms[idx].toFixed(2));
      })(),
      mapOutboxPending: this.mapOutboxPendingGauge,
      prismaP1008Total: this.prismaP1008Total,
    };
  }
}
