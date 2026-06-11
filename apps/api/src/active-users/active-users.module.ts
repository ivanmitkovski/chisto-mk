import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminActiveUsersController } from './controllers/admin-active-users.controller';
import { PresenceController } from './controllers/presence.controller';
import { UserActivityListener } from './listeners/user-activity.listener';
import { ActiveUsersAdminService } from './services/active-users-admin.service';
import { ActiveUsersMetricsCronService } from './services/active-users-metrics-cron.service';
import { ActiveUsersPresenceService } from './services/active-users-presence.service';
import { ActiveUsersRealtimeService } from './services/active-users-realtime.service';
import { ActiveUsersSessionEnrichmentService } from './services/active-users-session-enrichment.service';
import { ActivityRetentionCronService } from './services/activity-retention-cron.service';
import { AdminAlertEvaluationService } from './services/admin-alert-evaluation.service';
import { GeoIpService } from './services/geo-ip.service';
import { PresenceStoreService } from './services/presence-store.service';
import { UserActivityService } from './services/user-activity.service';

@Module({
  imports: [PrismaModule, AuditModule],
  controllers: [PresenceController, AdminActiveUsersController],
  providers: [
    GeoIpService,
    ActiveUsersRealtimeService,
    UserActivityService,
    PresenceStoreService,
    ActiveUsersPresenceService,
    ActiveUsersSessionEnrichmentService,
    ActiveUsersAdminService,
    ActiveUsersMetricsCronService,
    ActivityRetentionCronService,
    AdminAlertEvaluationService,
    UserActivityListener,
  ],
  exports: [
    ActiveUsersPresenceService,
    ActiveUsersRealtimeService,
    UserActivityService,
    ActiveUsersSessionEnrichmentService,
  ],
})
export class ActiveUsersModule {}
