export class ObservabilityStore {
  private static requestsTotal = 0;
  private static requestsFailed = 0;
  private static requestDurationsMs: number[] = [];
  private static feedRequestsTotal = 0;
  private static feedCacheHits = 0;
  private static feedDurationsMs: number[] = [];
  private static feedCandidatePoolSizes: number[] = [];
  private static feedFeedbackCounts: Record<string, number> = {};
  private static feedCacheInvalidationCounts: Record<string, number> = {};
  private static feedReasonCodeCounts: Record<string, number> = {};
  private static feedPaginationContinuityIssues = 0;
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
  private static mapFallbackResponses = 0;
  private static mapDurationsMs: number[] = [];
  private static mapCandidatePoolSizes: number[] = [];
  private static mapSseConnectionsTotal = 0;
  private static mapSseConnectionsActive = 0;
  private static mapSseReconnectHints = 0;
  private static mapSseEventsEmitted = 0;
  private static mapSseReplayEvents = 0;
  private static cleanupEventStaffPendingSignals = 0;
  private static cleanupEventPublishedAudienceNotified = 0;
  private static cleanupEventModerationApproved = 0;
  private static impactReceiptFetchTotal = 0;

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

  static recordFeedReasonCodes(reasonCodes: string[]): void {
    for (const reason of reasonCodes) {
      const key = reason || 'unknown';
      this.feedReasonCodeCounts[key] = (this.feedReasonCodeCounts[key] ?? 0) + 1;
    }
  }

  static recordFeedPaginationContinuityIssue(): void {
    this.feedPaginationContinuityIssues += 1;
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
      feedReasonCodeCounts: this.feedReasonCodeCounts,
      feedPaginationContinuityIssues: this.feedPaginationContinuityIssues,
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
      cleanupEventStaffPendingSignals: this.cleanupEventStaffPendingSignals,
      cleanupEventPublishedAudienceNotified: this.cleanupEventPublishedAudienceNotified,
      cleanupEventModerationApproved: this.cleanupEventModerationApproved,
      impactReceiptFetchTotal: this.impactReceiptFetchTotal,
    };
  }
}
