import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { ReportsModule } from './reports/reports.module';
import { ReportsOwnerWsModule } from './reports/owner-events/reports-owner-ws.module';
import { SitesModule } from './sites/sites.module';
import { AuthModule } from './auth/auth.module';
import { AdminRealtimeModule } from './admin-realtime/admin-realtime.module';
import { AdminModule } from './admin/admin.module';
import { AdminNotificationsModule } from './admin-notifications/admin-notifications.module';
import { HealthModule } from './health/health.module';
import { AuditModule } from './audit/audit.module';
import { SessionsModule } from './sessions/sessions.module';
import { AdminUsersModule } from './admin-users/admin-users.module';
import { SystemConfigModule } from './system-config/system-config.module';
import { FeatureFlagsModule } from './feature-flags/feature-flags.module';
import { PublicConfigModule } from './public-config/public-config.module';
import { CleanupEventsModule } from './cleanup-events/cleanup-events.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ObservabilityModule } from './observability/observability.module';
import { GamificationModule } from './gamification/gamification.module';
import { EventsModule } from './events/events.module';
import { EventChatModule } from './event-chat/event-chat.module';
import { WebhooksModule } from './webhooks/webhooks.module';
import { RedisIoAdapterLifecycle } from './common/adapters/redis-io-adapter.lifecycle';
import { DiscoveryAnalyticsModule } from './discovery-analytics/discovery-analytics.module';
import { LoggerModule } from 'nestjs-pino';
import { safePinoReqSerializer } from './common/logging/safe-pino-req.serializer';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    LoggerModule.forRoot({
      pinoHttp: {
        autoLogging: false,
        serializers: {
          req: safePinoReqSerializer,
        },
        redact: {
          paths: [
            'req.headers.authorization',
            'req.headers.Authorization',
            'req.headers.cookie',
            'req.headers.Cookie',
            'req.body.refreshToken',
            'req.body.deviceToken',
            'req.body.token',
            'req.body.otp',
            'req.body.code',
            'req.body.password',
            'req.body.newPassword',
            'req.body.currentPassword',
            'req.body.mfaSecret',
            'req.body.privateKey',
          ],
          remove: true,
        },
      },
    }),
    EventEmitterModule.forRoot(),
    StorageModule,
    HealthModule,
    ThrottlerModule.forRoot([{
      ttl: 60_000,
      limit: 60,
    }]),
    PrismaModule,
    AuditModule,
    AuthModule,
    SessionsModule,
    SitesModule,
    ReportsModule,
    ReportsOwnerWsModule,
    AdminRealtimeModule,
    AdminModule,
    AdminNotificationsModule,
    AdminUsersModule,
    SystemConfigModule,
    FeatureFlagsModule,
    PublicConfigModule,
    CleanupEventsModule,
    NotificationsModule,
    ObservabilityModule.register(),
    GamificationModule,
    EventsModule,
    EventChatModule,
    WebhooksModule,
    DiscoveryAnalyticsModule.register(),
  ],
  controllers: [AppController],
  providers: [
    AppService,
    RedisIoAdapterLifecycle,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
