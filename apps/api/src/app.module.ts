import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { ReportsModule } from './reports/reports.module';
import { SitesModule } from './sites/sites.module';
import { AuthModule } from './auth/auth.module';
import { AdminEventsModule } from './admin-events/admin-events.module';
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
import { RedisIoAdapterLifecycle } from './common/adapters/redis-io-adapter.lifecycle';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    EventEmitterModule.forRoot(),
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
    AdminEventsModule,
    AdminModule,
    AdminNotificationsModule,
    AdminUsersModule,
    SystemConfigModule,
    FeatureFlagsModule,
    PublicConfigModule,
    CleanupEventsModule,
    NotificationsModule,
    ObservabilityModule,
    GamificationModule,
    EventsModule,
    EventChatModule,
  ],
  controllers: [AppController],
  providers: [AppService, RedisIoAdapterLifecycle],
})
export class AppModule {}
