import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FcmPushService } from './fcm-push.service';
import { remediationForFcmErrorCode } from '../util/fcm-error-codes';

export type PushDiagnosticsTopErrorCode = {
  code: string;
  count: number;
};

@Injectable()
export class PushDiagnosticsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmPushService,
  ) {}

  async getDiagnostics(): Promise<{
    fcmEnabled: boolean;
    fcmReady: boolean;
    projectId: string | null;
    deadLetterTotal: number;
    topErrorCodes: PushDiagnosticsTopErrorCode[];
    remediation: string | null;
  }> {
    const [deadLetterTotal, grouped] = await Promise.all([
      this.prisma.notificationOutbox.count({
        where: { failedPermanently: true },
      }),
      this.prisma.notificationOutbox.groupBy({
        by: ['lastErrorCode'],
        where: { failedPermanently: true },
        _count: { _all: true },
      }),
    ]);

    const topErrorCodes: PushDiagnosticsTopErrorCode[] = grouped
      .map((row) => ({
        code: row.lastErrorCode ?? 'UNKNOWN',
        count: row._count._all,
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    const dominantCode = topErrorCodes[0]?.code ?? null;
    let remediation = remediationForFcmErrorCode(dominantCode);
    if (!this.fcm.isReady() && this.fcm.isEnabled()) {
      remediation =
        remediation ??
        'FCM is enabled but Firebase Admin failed to initialize. Check FIREBASE_SERVICE_ACCOUNT_JSON.';
    }

    return {
      fcmEnabled: this.fcm.isEnabled(),
      fcmReady: this.fcm.isReady(),
      projectId: this.fcm.getProjectId(),
      deadLetterTotal,
      topErrorCodes,
      remediation,
    };
  }
}
