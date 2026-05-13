import { Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';
import { ObservabilityStore } from '../observability/observability.store';
import { CircuitBreaker, CircuitBreakerOpenError } from '../common/resilience/circuit-breaker';

@Injectable()
export class FcmPushService implements OnModuleInit {
  private readonly logger = new Logger(FcmPushService.name);
  private app: admin.app.App | null = null;
  private readonly circuitBreaker = new CircuitBreaker({
    name: 'fcm',
    failureThreshold: 10,
    resetTimeoutMs: 60_000,
    halfOpenMaxAttempts: 2,
  });

  constructor(
    @Optional() private readonly configService: ConfigService | null,
    private readonly prisma: PrismaService,
  ) {}

  onModuleInit() {
    if (!this.isEnabled()) {
      this.logger.warn('FCM is disabled — PUSH_FCM_ENABLED is not set or false');
      return;
    }

    const credentialsJson =
      this.configService?.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON') ??
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
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
    const v =
      this.configService?.get<string>('PUSH_FCM_ENABLED', 'false') ??
      process.env.PUSH_FCM_ENABLED ??
      'false';
    return v === 'true';
  }

  isReady(): boolean {
    return this.app !== null;
  }

  async sendToToken(
    token: string,
    payload: {
      title: string;
      body: string;
      data?: Record<string, string>;
      userId?: string;
      androidChannelId?: string;
    },
  ): Promise<{ success: boolean; canonicalToken?: string; shouldRevoke?: boolean }> {
    if (!this.app) {
      return { success: false };
    }

    let badge = 1;
    if (payload.userId) {
      try {
        badge = await this.prisma.userNotification.count({
          where: { userId: payload.userId, isRead: false, archivedAt: null },
        });
        badge = Math.max(badge, 1);
      } catch {
        badge = 1;
      }
    }

    const channelId = payload.androidChannelId ?? this.resolveAndroidChannel(payload.data);

    const message: admin.messaging.Message = {
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data ?? {},
      android: {
        priority: 'high',
        notification: { channelId },
      },
      apns: {
        payload: {
          aps: {
            alert: { title: payload.title, body: payload.body },
            sound: 'default',
            badge,
          },
        },
      },
    };

    try {
      return await this.circuitBreaker.execute(async () => {
        try {
          await admin.messaging(this.app!).send(message);
          ObservabilityStore.recordPushSend('success');
          return { success: true } as const;
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
            return { success: false, shouldRevoke: true } as const;
          }

          this.logger.warn(`FCM send failed: ${code}`);
          ObservabilityStore.recordPushSend('failure');
          throw error;
        }
      });
    } catch (error) {
      if (error instanceof CircuitBreakerOpenError) {
        this.logger.warn(`FCM circuit breaker open, skipping send`);
        ObservabilityStore.recordPushSend('failure');
        return { success: false };
      }
      return { success: false };
    }
  }

  private resolveAndroidChannel(data?: Record<string, string>): string {
    const type = data?.['notificationType'];
    switch (type) {
      case 'REPORT_STATUS':
      case 'NEARBY_REPORT':
        return 'chisto_reports';
      case 'CLEANUP_EVENT':
        return 'chisto_events';
      case 'EVENT_CHAT':
        return 'chisto_event_chat';
      case 'UPVOTE':
      case 'COMMENT':
        return 'chisto_social';
      case 'SYSTEM':
      case 'ACHIEVEMENT':
      case 'WELCOME':
        return 'chisto_system';
      default:
        return 'chisto_default';
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
