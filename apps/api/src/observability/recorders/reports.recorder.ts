import { legacySnapshotGauges } from '../util/prom-registry';
import { p95Ms, trimRollingBuffer } from './percentile.util';

let reportsSubmitSuccess = 0;
let reportsSubmitError = 0;
let reportsUploadSuccess = 0;
let reportsUploadError = 0;
let reportsSignedUrlIssued = 0;
let reportsSignedUrlCacheHit = 0;
let reportsSignedUrlError = 0;
let reportsSubmitDurationsMs: number[] = [];
let reportsSignedUrlLatencyMs: number[] = [];
let reportApprovalPointsAwardedTotal = 0;
let reportApprovalPointsCappedTotal = 0;
let reportApprovalPointsRevokedTotal = 0;
let reportSideEffectFailedTotal = 0;

export function recordReportSideEffectFailed(): void {
  reportSideEffectFailedTotal += 1;
  legacySnapshotGauges.reportSideEffectFailed.set(reportSideEffectFailedTotal);
}

export function recordReportApprovalPointsAwarded(delta: number): void {
  if (delta > 0) {
    reportApprovalPointsAwardedTotal += delta;
  }
}

export function recordReportApprovalPointsCapped(): void {
  reportApprovalPointsCappedTotal += 1;
}

export function recordReportApprovalPointsRevoked(amount: number): void {
  if (amount > 0) {
    reportApprovalPointsRevokedTotal += amount;
  }
}

export function recordReportSubmit(outcome: 'success' | 'error', durationMs?: number): void {
  if (outcome === 'success') {
    reportsSubmitSuccess += 1;
  } else {
    reportsSubmitError += 1;
  }
  if (durationMs != null && durationMs >= 0) {
    reportsSubmitDurationsMs.push(durationMs);
    reportsSubmitDurationsMs = trimRollingBuffer(reportsSubmitDurationsMs);
  }
}

export function recordReportUpload(outcome: 'success' | 'error'): void {
  if (outcome === 'success') {
    reportsUploadSuccess += 1;
  } else {
    reportsUploadError += 1;
  }
}

export function recordReportSignedUrl(outcome: 'issued' | 'cache_hit' | 'error'): void {
  if (outcome === 'issued') {
    reportsSignedUrlIssued += 1;
  } else if (outcome === 'cache_hit') {
    reportsSignedUrlCacheHit += 1;
  } else {
    reportsSignedUrlError += 1;
  }
}

export function recordReportSignedUrlLatencyMs(durationMs: number): void {
  if (durationMs < 0) {
    return;
  }
  reportsSignedUrlLatencyMs.push(durationMs);
  reportsSignedUrlLatencyMs = trimRollingBuffer(reportsSignedUrlLatencyMs);
}

export function snapshot() {
  return {
    reportsSubmitSuccess,
    reportsSubmitError,
    reportApprovalPointsAwardedTotal,
    reportApprovalPointsCappedTotal,
    reportApprovalPointsRevokedTotal,
    reportsUploadSuccess,
    reportsUploadError,
    reportsSignedUrlIssued,
    reportsSignedUrlCacheHit,
    reportsSignedUrlError,
    reportsSubmitP95Ms: p95Ms(reportsSubmitDurationsMs),
    reportsSignedUrlLatencyP95Ms: p95Ms(reportsSignedUrlLatencyMs),
    reportSideEffectFailedTotal,
  };
}
