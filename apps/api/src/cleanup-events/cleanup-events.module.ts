import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { EventScheduleConflictModule } from '../event-schedule-conflict/event-schedule-conflict.module';
import { GamificationModule } from '../gamification/gamification.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { CleanupEventsAnalyticsService } from './cleanup-events-analytics.service';
import { CleanupEventsController } from './cleanup-events.controller';
import { CleanupEventsListService } from './cleanup-events-list.service';
import { CleanupEventsMutationsService } from './cleanup-events-mutations.service';
import { CleanupEventsService } from './cleanup-events.service';

@Module({
  imports: [
    AdminEventsModule,
    AuditModule,
    EventScheduleConflictModule,
    GamificationModule,
    NotificationsModule,
    ReportsUploadModule,
  ],
  controllers: [CleanupEventsController],
  providers: [
    CleanupEventsAnalyticsService,
    CleanupEventsListService,
    CleanupEventsMutationsService,
    CleanupEventsService,
  ],
})
export class CleanupEventsModule {}
