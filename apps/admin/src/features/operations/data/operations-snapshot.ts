export type PanelState<T> =
  | { status: 'ok'; data: T; updatedAt: string }
  | { status: 'error'; error: string; updatedAt: string }
  | { status: 'forbidden'; updatedAt: string };

export type PushOutboxTotals = {
  deliveredTotal: number;
  failedPermanentlyTotal: number;
  pendingTotal: number;
};

export type PushStatsData = {
  sendsTotal: number;
  sendsSuccess: number;
  sendsFailure: number;
  sendsRevoked: number;
  sendsByType: Record<string, { success: number; failure: number; revoked: number }>;
  tokenRevocations: number;
  queueRetries: number;
  inboxReads: number;
  queueDepth: number;
  activeLeases: number;
  deadLetterCount: number;
  outbox: PushOutboxTotals;
};

export type DeliveryReportData = {
  sends: {
    total: number;
    success: number;
    failure: number;
    revoked: number;
    byType: Record<string, { success: number; failure: number; revoked: number }>;
  };
  inbox: { notificationsSent: number; notificationsOpened: number; openRate: number };
  queue: { depth: number; activeLeases: number; deadLetterCount: number; retries: number };
  outbox: PushOutboxTotals;
};

export type OperationsSnapshot = {
  pushStats: PanelState<PushStatsData>;
  deliveryReport: PanelState<DeliveryReportData>;
  deadLetters: PanelState<{
    data: Array<{
      id: string;
      userNotificationId: string;
      deviceTokenSuffix: string;
      attempts: number;
      lastErrorCode: string | null;
      lastErrorMessage: string | null;
      lastAttemptAt: string | null;
      createdAt: string;
    }>;
    meta: { page: number; limit: number; total: number };
  }>;
  emailDeadLetters: PanelState<{
    data: Array<{
      id: string;
      userId: string;
      templateId: string;
      attempts: number;
      lastError: string | null;
      lastAttemptAt: string | null;
      createdAt: string;
    }>;
    meta: { page: number; limit: number; total: number };
  }>;
  mapHealth: PanelState<{
    status: string;
    mapUseProjection: boolean;
    outboxPending: number;
    staleHotProjectionRows: number;
    alerts: string[];
  }>;
  mapDeep: PanelState<{
    status: string;
    durationMs: number;
    matchCount: number;
    queryPath: string;
    alerts: string[];
  }>;
  gdprAudit: PanelState<{
    data: Array<{ id: string; action: string; createdAt: string; actorEmail: string | null }>;
    meta: { total: number };
  }>;
  feedDiagnostics: PanelState<{
    reasonCodes: Array<{ code: string; count: number }>;
    rankDriftSnapshot: Array<{ siteId: string; score: number; reasons: string[] }>;
    recentIntegrityDemotions: number;
  }>;
  sideEffects: PanelState<{ pendingCount: number }>;
  emailSuppressions: PanelState<{ meta: { total: number } }>;
  systemInfo: PanelState<{
    version: string;
    gitSha: string | null;
    nodeEnv: string;
    region: string | null;
    startedAt: string;
    uptimeSeconds: number;
    fcmEnabled: boolean;
  }>;
  workers: PanelState<{
    workers: Array<{
      name: string;
      running: boolean;
      intervalMs: number;
      startedAt: string;
      lastRunAt: string | null;
      lastSuccessAt: string | null;
      lastError: string | null;
      stale: boolean;
    }>;
    perReplica: boolean;
  }>;
  readiness: PanelState<{
    status: 'ok' | 'degraded';
    database: 'ok' | 'fail';
    redis: string;
    s3: string;
  }>;
};

function normalizePushOutboxTotals(
  raw: Partial<PushOutboxTotals> | undefined,
  fallback: { queueDepth: number; deadLetterCount: number },
): PushOutboxTotals {
  return {
    deliveredTotal: raw?.deliveredTotal ?? 0,
    failedPermanentlyTotal: raw?.failedPermanentlyTotal ?? fallback.deadLetterCount,
    pendingTotal: raw?.pendingTotal ?? fallback.queueDepth,
  };
}

/** Back-compat for API replicas that predate DB outbox totals on push-stats. */
export function normalizePushStats(raw: Partial<PushStatsData> | null | undefined): PushStatsData {
  const queueDepth = raw?.queueDepth ?? 0;
  const deadLetterCount = raw?.deadLetterCount ?? 0;
  return {
    sendsTotal: raw?.sendsTotal ?? 0,
    sendsSuccess: raw?.sendsSuccess ?? 0,
    sendsFailure: raw?.sendsFailure ?? 0,
    sendsRevoked: raw?.sendsRevoked ?? 0,
    sendsByType: raw?.sendsByType ?? {},
    tokenRevocations: raw?.tokenRevocations ?? 0,
    queueRetries: raw?.queueRetries ?? 0,
    inboxReads: raw?.inboxReads ?? 0,
    queueDepth,
    activeLeases: raw?.activeLeases ?? 0,
    deadLetterCount,
    outbox: normalizePushOutboxTotals(raw?.outbox, { queueDepth, deadLetterCount }),
  };
}

export function normalizeDeliveryReport(
  raw: Partial<DeliveryReportData> | null | undefined,
): DeliveryReportData {
  const queueDepth = raw?.queue?.depth ?? 0;
  const deadLetterCount = raw?.queue?.deadLetterCount ?? 0;
  return {
    sends: {
      total: raw?.sends?.total ?? 0,
      success: raw?.sends?.success ?? 0,
      failure: raw?.sends?.failure ?? 0,
      revoked: raw?.sends?.revoked ?? 0,
      byType: raw?.sends?.byType ?? {},
    },
    inbox: {
      notificationsSent: raw?.inbox?.notificationsSent ?? 0,
      notificationsOpened: raw?.inbox?.notificationsOpened ?? 0,
      openRate: raw?.inbox?.openRate ?? 0,
    },
    queue: {
      depth: queueDepth,
      activeLeases: raw?.queue?.activeLeases ?? 0,
      deadLetterCount,
      retries: raw?.queue?.retries ?? 0,
    },
    outbox: normalizePushOutboxTotals(raw?.outbox, { queueDepth, deadLetterCount }),
  };
}

/** Ensures panel payloads match current UI expectations (legacy API / stale RSC props). */
export function sanitizeOperationsSnapshot(snapshot: OperationsSnapshot): OperationsSnapshot {
  return {
    ...snapshot,
    pushStats:
      snapshot.pushStats.status === 'ok'
        ? { ...snapshot.pushStats, data: normalizePushStats(snapshot.pushStats.data) }
        : snapshot.pushStats,
    deliveryReport:
      snapshot.deliveryReport.status === 'ok'
        ? { ...snapshot.deliveryReport, data: normalizeDeliveryReport(snapshot.deliveryReport.data) }
        : snapshot.deliveryReport,
  };
}
