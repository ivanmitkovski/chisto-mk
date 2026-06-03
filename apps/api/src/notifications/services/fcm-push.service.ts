import { Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PrismaService } from '../../prisma/prisma.service';
import { ObservabilityStore } from '../../observability/observability.store';
import { CircuitBreaker, CircuitBreakerOpenError } from '../../common/resilience/circuit-breaker';
import {
  buildAndroidFcmOptions,
  buildApnsConfig,
  isEventChatClientDisplayed,
  isSilentBadgeSync,
  type FcmPushData,
} from '../util/fcm-apns-payload';

export type FcmSendPayload = {
  title: string;
  body: string;
  subtitle?: string;
  data?: Record<string, string>;
  userId?: string;
  androidChannelId?: string;
  /** When set, skips per-send unread count query (dispatcher provides truth). */
  unreadCount?: number;
};

const BADGE_SYNC_THROTTLE_MS = 15 * 60 * 1000;

@Injectable()
export class FcmPushService implements OnModuleInit {
  private readonly logger = new Logger(FcmPushService.name);
  private app: admin.app.App | null = null;
  private readonly lastBadgeSyncAtByUser = new Map<string, number>();
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

  async resolveUnreadBadge(userId: string): Promise<number> {
    try {
      return await this.prisma.userNotification.count({
        where: { userId, isRead: false, archivedAt: null },
      });
    } catch {
      return 0;
    }
  }

  async sendToToken(
    token: string,
    payload: FcmSendPayload,
  ): Promise<{ success: boolean; canonicalToken?: string; shouldRevoke?: boolean }> {
    if (!this.app) {
      return { success: false };
    }

    let badge = payload.unreadCount;
    if (badge == null && payload.userId) {
      badge = await this.resolveUnreadBadge(payload.userId);
    }
    if (badge == null) {
      badge = 0;
    }

    const baseData = payload.data ?? {};
    const silent = isSilentBadgeSync(baseData as FcmPushData);
    const data: Record<string, string> = silent
      ? { ...baseData }
      : {
          ...baseData,
          title: payload.title,
          body: payload.body,
        };
    const clientDisplayed = isEventChatClientDisplayed(data);
    const channelId = payload.androidChannelId ?? this.resolveAndroidChannel(payload.data);
    const apns = buildApnsConfig({
      title: payload.title,
      body: payload.body,
      ...(payload.subtitle ? { subtitle: payload.subtitle } : {}),
      badge,
      data,
      clientDisplayed,
    });
    const androidOpts = buildAndroidFcmOptions(data);
    const omitSystemNotification = silent || clientDisplayed;

    const message: admin.messaging.Message = {
      token,
      ...(omitSystemNotification
        ? {}
        : {
            notification: {
              title: payload.title,
              body: payload.body,
            },
          }),
      data,
      android: {
        priority: 'high',
        ttl: androidOpts.ttl,
        ...(androidOpts.collapseKey ? { collapseKey: androidOpts.collapseKey } : {}),
        ...(omitSystemNotification
          ? {}
          : {
              notification: {
                channelId,
                ...(androidOpts.notification?.tag ? { tag: androidOpts.notification.tag } : {}),
              },
            }),
      },
      apns: {
        headers: apns.headers,
        payload: apns.payload,
      },
    };

    const notificationType = payload.data?.['notificationType'] ?? payload.data?.['type'] ?? 'unknown';

    try {
      return await this.circuitBreaker.execute(async () => {
        try {
          await admin.messaging(this.app!).send(message);
          ObservabilityStore.recordPushSend('success', notificationType);
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
            ObservabilityStore.recordPushSend('revoked', notificationType);
            return { success: false, shouldRevoke: true } as const;
          }

          this.logger.warn(`FCM send failed: ${code}`);
          ObservabilityStore.recordPushSend('failure', notificationType);
          throw error;
        }
      });
    } catch (error) {
      if (error instanceof CircuitBreakerOpenError) {
        this.logger.warn(`FCM circuit breaker open, skipping send`);
        ObservabilityStore.recordPushSend('failure', notificationType);
        return { success: false };
      }
      return { success: false };
    }
  }

  private resolveAndroidChannel(data?: Record<string, string>): string {
    const type = data?.['notificationType'] ?? data?.['type'];
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

  /**
   * Silent background badge refresh (iOS content-available / Android data-only).
   * Throttled per user — at most once per 15 minutes.
   */
  async maybeSendBadgeSync(
    userId: string,
    token: string,
    unreadCount: number,
  ): Promise<void> {
    if (!this.app) return;
    const now = Date.now();
    const last = this.lastBadgeSyncAtByUser.get(userId) ?? 0;
    if (now - last < BADGE_SYNC_THROTTLE_MS) {
      return;
    }
    this.lastBadgeSyncAtByUser.set(userId, now);
    await this.sendToToken(token, {
      title: '',
      body: '',
      unreadCount,
      userId,
      data: {
        kind: 'badge_sync',
        unreadCount: String(unreadCount),
      },
    });
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
