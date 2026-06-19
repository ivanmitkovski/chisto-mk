import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { WorkerHeartbeatRegistry } from '../../observability/worker-heartbeat.registry';
import { FcmPushService } from './fcm-push.service';
import { PushPipelineHealthService } from './push-pipeline-health.service';
import { remediationForFcmErrorCode } from '../util/fcm-error-codes';

export type PushDiagnosticsTopErrorCode = {
  code: string;
  count: number;
};

const PUSH_WORKER_NAME = 'push-delivery';

@Injectable()
export class PushDiagnosticsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmPushService,
    private readonly pipelineHealth: PushPipelineHealthService,
  ) {}

  async getDiagnostics(): Promise<{
    fcmEnabled: boolean;
    fcmReady: boolean;
    projectId: string | null;
    credentialStatus: string;
    credentialParseError: string | null;
    deadLetterTotal: number;
    topErrorCodes: PushDiagnosticsTopErrorCode[];
    errorsLast1h: PushDiagnosticsTopErrorCode[];
    errorsLast24h: PushDiagnosticsTopErrorCode[];
    queueDepth: number;
    activeLeases: number;
    pendingCount: number;
    registeredDeviceTokens: number;
    workerStatus: {
      expected: boolean;
      running: boolean;
      stale: boolean;
      lastError?: string;
    };
    remediation: string | null;
  }> {
    const health = await this.pipelineHealth.getHealthSnapshot();
    const credential = this.fcm.getCredentialValidation();
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const [deadLetterTotal, grouped, grouped1h, grouped24h, registeredDeviceTokens] =
      await Promise.all([
        this.prisma.notificationOutbox.count({
          where: { failedPermanently: true },
        }),
        this.prisma.notificationOutbox.groupBy({
          by: ['lastErrorCode'],
          where: { failedPermanently: true },
          _count: { _all: true },
        }),
        this.prisma.notificationOutbox.groupBy({
          by: ['lastErrorCode'],
          where: {
            failedPermanently: true,
            lastAttemptAt: { gte: oneHourAgo },
          },
          _count: { _all: true },
        }),
        this.prisma.notificationOutbox.groupBy({
          by: ['lastErrorCode'],
          where: {
            failedPermanently: true,
            lastAttemptAt: { gte: oneDayAgo },
          },
          _count: { _all: true },
        }),
        this.prisma.userDeviceToken.count({
          where: { revokedAt: null },
        }),
      ]);

    const topErrorCodes = this.mapErrorGroups(grouped);
    const errorsLast1h = this.mapErrorGroups(grouped1h);
    const errorsLast24h = this.mapErrorGroups(grouped24h);

    const dominantCode = topErrorCodes[0]?.code ?? null;
    let remediation = remediationForFcmErrorCode(dominantCode);
    if (credential.status === 'invalid_json') {
      remediation =
        'FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON. Re-save as single-line: jq -c . firebase-adminsdk.json';
    } else if (credential.status === 'invalid_structure') {
      remediation =
        credential.parseError ??
        'FIREBASE_SERVICE_ACCOUNT_JSON is missing required service account fields.';
    } else if (!this.fcm.isReady() && this.fcm.isEnabled()) {
      remediation =
        remediation ??
        'FCM is enabled but Firebase Admin failed to initialize. Check FIREBASE_SERVICE_ACCOUNT_JSON.';
    }

    const workerSnap = WorkerHeartbeatRegistry.snapshot().find((w) => w.name === PUSH_WORKER_NAME);

    return {
      fcmEnabled: this.fcm.isEnabled(),
      fcmReady: this.fcm.isReady(),
      projectId: this.fcm.getProjectId() ?? credential.projectId,
      credentialStatus: credential.status,
      credentialParseError: credential.parseError,
      deadLetterTotal,
      topErrorCodes,
      errorsLast1h,
      errorsLast24h,
      queueDepth: health.outbox.pending,
      activeLeases: health.outbox.leased,
      pendingCount: health.outbox.pending,
      registeredDeviceTokens,
      workerStatus: {
        expected: health.worker.expected,
        running: health.worker.running,
        stale: health.worker.stale,
        ...(workerSnap?.lastError ? { lastError: workerSnap.lastError } : {}),
      },
      remediation,
    };
  }

  private mapErrorGroups(
    grouped: Array<{ lastErrorCode: string | null; _count: { _all: number } }>,
  ): PushDiagnosticsTopErrorCode[] {
    return grouped
      .map((row) => ({
        code: row.lastErrorCode ?? 'UNKNOWN',
        count: row._count._all,
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }
}
