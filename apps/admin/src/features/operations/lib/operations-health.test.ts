import { describe, expect, it } from 'vitest';
import type { OperationsSnapshot } from '../data/operations-adapter';
import { derivePanelHealth, deriveSystemStatus } from './operations-health';

function okPanel<T>(data: T) {
  return { status: 'ok' as const, data, updatedAt: new Date().toISOString() };
}

function baseSnapshot(overrides: Partial<OperationsSnapshot> = {}): OperationsSnapshot {
  return {
    pushStats: okPanel({
      sendsTotal: 0,
      sendsSuccess: 0,
      sendsFailure: 0,
      sendsRevoked: 0,
      sendsByType: {},
      tokenRevocations: 0,
      queueRetries: 0,
      inboxReads: 0,
      queueDepth: 0,
      activeLeases: 0,
      deadLetterCount: 0,
      outbox: {
        deliveredTotal: 0,
        failedPermanentlyTotal: 0,
        pendingTotal: 0,
      },
    }),
    deliveryReport: okPanel({
      sends: { total: 0, success: 0, failure: 0, revoked: 0, byType: {} },
      inbox: { notificationsSent: 100, notificationsOpened: 50, openRate: 0.5 },
      queue: { depth: 0, activeLeases: 0, deadLetterCount: 0, retries: 0 },
      outbox: {
        deliveredTotal: 0,
        failedPermanentlyTotal: 0,
        pendingTotal: 0,
      },
    }),
    deadLetters: okPanel({ data: [], meta: { page: 1, limit: 5, total: 0 } }),
    emailDeadLetters: okPanel({ data: [], meta: { page: 1, limit: 5, total: 0 } }),
    mapHealth: okPanel({
      status: 'ok',
      mapUseProjection: true,
      outboxPending: 0,
      staleHotProjectionRows: 0,
      alerts: [],
    }),
    mapDeep: okPanel({
      status: 'ok',
      durationMs: 50,
      matchCount: 1,
      queryPath: 'postgis_dwithin',
      alerts: [],
    }),
    gdprAudit: okPanel({ data: [], meta: { total: 0 } }),
    feedDiagnostics: okPanel({
      reasonCodes: [],
      rankDriftSnapshot: [],
      recentIntegrityDemotions: 0,
    }),
    sideEffects: okPanel({ pendingCount: 0 }),
    emailSuppressions: okPanel({ meta: { total: 0 } }),
    systemInfo: okPanel({
      version: '0.1.0',
      gitSha: null,
      nodeEnv: 'test',
      region: null,
      startedAt: new Date().toISOString(),
      uptimeSeconds: 10,
      fcmEnabled: false,
    }),
    workers: okPanel({ workers: [], perReplica: true }),
    readiness: okPanel({ status: 'ok', database: 'ok', redis: 'skipped', s3: 'skipped' }),
    ...overrides,
  };
}

describe('operations health', () => {
  it('marks push stats critical when queue depth exceeds critical threshold', () => {
    const snapshot = baseSnapshot({
      pushStats: okPanel({
        sendsTotal: 10,
        sendsSuccess: 10,
        sendsFailure: 0,
        sendsRevoked: 0,
        sendsByType: {},
        tokenRevocations: 0,
        queueRetries: 0,
        inboxReads: 0,
        queueDepth: 150,
        activeLeases: 0,
        deadLetterCount: 0,
      }),
    });
    expect(derivePanelHealth('pushStats', snapshot.pushStats)).toBe('critical');
  });

  it('aggregates system status as degraded when any panel warns', () => {
    const snapshot = baseSnapshot({
      deadLetters: okPanel({ data: [], meta: { page: 1, limit: 5, total: 2 } }),
    });
    const summary = deriveSystemStatus(snapshot);
    expect(summary.status).toBe('warn');
    expect(summary.warnCount).toBeGreaterThan(0);
  });

  it('returns critical system status when readiness is degraded', () => {
    const snapshot = baseSnapshot({
      readiness: okPanel({ status: 'degraded', database: 'fail', redis: 'ok', s3: 'ok' }),
    });
    expect(deriveSystemStatus(snapshot).status).toBe('critical');
  });
});
