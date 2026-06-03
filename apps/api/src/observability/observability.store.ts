import { fetchWithTimeout } from '../common/resilience/fetch-with-timeout';
import { legacySnapshotGauges, metricsPushFailedTotal } from './util/prom-registry';
import * as CleanupEventsRecorder from './recorders/cleanup-events.recorder';
import * as FeedRecorder from './recorders/feed.recorder';
import * as MapRecorder from './recorders/map.recorder';
import * as MiscRecorder from './recorders/misc.recorder';
import * as PushRecorder from './recorders/push.recorder';
import * as ReportsRecorder from './recorders/reports.recorder';
import * as RequestRecorder from './recorders/request.recorder';
import * as ShareRecorder from './recorders/share.recorder';

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
    g(
      'chisto_map_outbox_pending',
      snap.mapOutboxPending,
      'MapEventOutbox rows in PENDING status (last sampled)',
    );

    lines.push('# HELP chisto_prisma_p1008_total Public API responses mapped from Prisma P1008 timeouts');
    lines.push('# TYPE chisto_prisma_p1008_total counter');
    lines.push(`chisto_prisma_p1008_total ${MiscRecorder.getPrismaP1008Total()}`);
    const body = lines.join('\n') + '\n';
    const url = `${PUSH_GATEWAY_URL}/metrics/job/${JOB_NAME}`;
    try {
      await fetchWithTimeout(url, {
        method: 'POST',
        headers: { 'Content-Type': 'text/plain; version=0.0.4' },
        body,
        timeoutMs: 5_000,
      });
    } catch {
      metricsPushFailedTotal.inc();
    }
  }

  static recordReportSideEffectFailed = ReportsRecorder.recordReportSideEffectFailed;
  static recordReportApprovalPointsAwarded = ReportsRecorder.recordReportApprovalPointsAwarded;
  static recordReportApprovalPointsCapped = ReportsRecorder.recordReportApprovalPointsCapped;
  static recordReportApprovalPointsRevoked = ReportsRecorder.recordReportApprovalPointsRevoked;
  static recordReportSubmit = ReportsRecorder.recordReportSubmit;
  static recordReportUpload = ReportsRecorder.recordReportUpload;
  static recordReportSignedUrl = ReportsRecorder.recordReportSignedUrl;
  static recordReportSignedUrlLatencyMs = ReportsRecorder.recordReportSignedUrlLatencyMs;
  static recordShareLinkIssued = ShareRecorder.recordShareLinkIssued;
  static recordShareAttributionEvent = ShareRecorder.recordShareAttributionEvent;
  static recordCleanupEventStaffPendingSignals = CleanupEventsRecorder.recordCleanupEventStaffPendingSignals;
  static recordCleanupEventPublishedAudienceBatch =
    CleanupEventsRecorder.recordCleanupEventPublishedAudienceBatch;
  static recordCleanupEventModerationApproved = CleanupEventsRecorder.recordCleanupEventModerationApproved;
  static recordImpactReceiptFetch = MiscRecorder.recordImpactReceiptFetch;
  static recordRequest(durationMs: number, statusCode: number): void {
    RequestRecorder.recordRequest(durationMs, statusCode);
    this.syncLegacyPromGauges();
  }
  static recordFeedRequest = FeedRecorder.recordFeedRequest;
  static recordFeedFeedback = FeedRecorder.recordFeedFeedback;
  static recordFeedCacheInvalidation = FeedRecorder.recordFeedCacheInvalidation;
  static setFeedCacheEntries = FeedRecorder.setFeedCacheEntries;
  static recordFeedReasonCodes = FeedRecorder.recordFeedReasonCodes;
  static recordFeedPaginationContinuityIssue = FeedRecorder.recordFeedPaginationContinuityIssue;
  static recordFeedV2Request = FeedRecorder.recordFeedV2Request;
  static recordFeedV2StageLatency = FeedRecorder.recordFeedV2StageLatency;
  static setFeedV2ModelVersion = FeedRecorder.setFeedV2ModelVersion;
  static setFeedV2RankerMode = FeedRecorder.setFeedV2RankerMode;
  static recordFeedV2ShadowComparison = FeedRecorder.recordFeedV2ShadowComparison;
  static getPushSendsByType = PushRecorder.getPushSendsByType;
  static recordPushSend = PushRecorder.recordPushSend;
  static recordPushTokenRevocation = PushRecorder.recordPushTokenRevocation;
  static recordPushQueueRetry = PushRecorder.recordPushQueueRetry;
  static recordPushInboxRead = PushRecorder.recordPushInboxRead;
  static recordMapRequest = MapRecorder.recordMapRequest;
  static recordMapSseConnected = MapRecorder.recordMapSseConnected;
  static recordMapSseDisconnected = MapRecorder.recordMapSseDisconnected;
  static recordMapSseReconnectHint = MapRecorder.recordMapSseReconnectHint;
  static recordMapSseEventEmitted = MapRecorder.recordMapSseEventEmitted;
  static recordMapSseReplayEvents = MapRecorder.recordMapSseReplayEvents;
  static setMapCacheEntries = MapRecorder.setMapCacheEntries;
  static recordMapCacheInvalidation = MapRecorder.recordMapCacheInvalidation;
  static recordMapOutboxDispatch = MapRecorder.recordMapOutboxDispatch;
  static recordMapProjectionSnapshot = MapRecorder.recordMapProjectionSnapshot;
  static recordMapProjectionHotRefresh = MapRecorder.recordMapProjectionHotRefresh;
  static recordMapOutboxRowsPurged = MapRecorder.recordMapOutboxRowsPurged;
  static setMapOutboxPendingCount = MapRecorder.setMapOutboxPendingCount;
  static recordPrismaP1008Response = MiscRecorder.recordPrismaP1008Response;
  static recordMapZoomTierRequest = MapRecorder.recordMapZoomTierRequest;
  static recordMapQueryRowCount = MapRecorder.recordMapQueryRowCount;
  static setPushQueueStats = PushRecorder.setPushQueueStats;

  static syncLegacyPromGauges(): void {
    const snap = this.snapshot();
    legacySnapshotGauges.requestsTotal.set(snap.requestsTotal);
    legacySnapshotGauges.requestsFailed.set(snap.requestsFailed);
    legacySnapshotGauges.requestDurationP95Ms.set(snap.p95Ms);
    legacySnapshotGauges.pushDeadLetter.set(snap.pushDeadLetterCount);
    legacySnapshotGauges.mapOutboxFailed.set(snap.mapOutboxFailed);
    legacySnapshotGauges.reportSideEffectFailed.set(snap.reportSideEffectFailedTotal);
  }

  static snapshot() {
    return {
      ...RequestRecorder.snapshot(),
      ...FeedRecorder.snapshot(),
      ...PushRecorder.snapshot(),
      ...MapRecorder.snapshot(),
      ...ShareRecorder.snapshot(),
      ...ReportsRecorder.snapshot(),
      ...CleanupEventsRecorder.snapshot(),
      ...MiscRecorder.snapshot(),
    };
  }
}
