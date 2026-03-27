import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';
import { ObservabilityStore } from '../observability/observability.store';

@Injectable()
export class FcmPushService implements OnModuleInit {
  private readonly logger = new Logger(FcmPushService.name);
  private app: admin.app.App | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  onModuleInit() {
    if (!this.isEnabled()) {
      this.logger.warn('FCM is disabled — PUSH_FCM_ENABLED is not set or false');
      return;
    }

    const credentialsJson = this.configService.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (!credentialsJson) {
      this.logger.warn('FCM credentials missing — FIREBASE_SERVICE_ACCOUNT_JSON not set');
      return;
    }

    try {
      const credential = admin.credential.cert(JSON.parse(credentialsJson));
      this.app = admin.initializeApp({ credential });
      this.logger.log('Firebase Admin initialized');
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin', error);
    }
  }

  isEnabled(): boolean {
    return this.configService.get<string>('PUSH_FCM_ENABLED', 'false') === 'true';
  }

  isReady(): boolean {
    return this.app !== null;
  }

  async sendToToken(
    token: string,
    payload: { title: string; body: string; data?: Record<string, string> },
  ): Promise<{ success: boolean; canonicalToken?: string; shouldRevoke?: boolean }> {
    if (!this.app) {
      return { success: false };
    }

    const message: admin.messaging.Message = {
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data ?? {},
      android: {
        priority: 'high',
        notification: { channelId: 'chisto_default' },
      },
      apns: {
        payload: {
          aps: {
            alert: { title: payload.title, body: payload.body },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      await admin.messaging(this.app).send(message);
      ObservabilityStore.recordPushSend('success');
      return { success: true };
    } catch (error: unknown) {
      const fcmError = error as { code?: string };
      const code = fcmError?.code ?? 'unknown';

      const revokeCodes = new Set([
        'messaging/registration-token-not-registered',
        'messaging/invalid-registration-token',
        'messaging/invalid-argument',
      ]);

      if (revokeCodes.has(code)) {
        ObservabilityStore.recordPushSend('revoked');
        return { success: false, shouldRevoke: true };
      }

      this.logger.warn(`FCM send failed: ${code}`);
      ObservabilityStore.recordPushSend('failure');
      return { success: false };
    }
  }

  async revokeToken(token: string): Promise<void> {
    await this.prisma.userDeviceToken.updateMany({
      where: { token },
      data: { revokedAt: new Date() },
    });
    ObservabilityStore.recordPushTokenRevocation();
  }

  async incrementFailureCount(token: string): Promise<void> {
    await this.prisma.userDeviceToken.updateMany({
      where: { token },
      data: { failureCount: { increment: 1 } },
    });
  }
}
