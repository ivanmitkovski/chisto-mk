import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { AuditModule } from '../audit/audit.module';
import { EventScheduleConflictModule } from '../event-schedule-conflict/event-schedule-conflict.module';
import { GamificationModule } from '../gamification/gamification.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { CleanupEventsAnalyticsService } from './cleanup-events-analytics.service';
import { CleanupEventsController } from './cleanup-events.controller';
import { CleanupEventsListService } from './cleanup-events-list.service';
import { CleanupEventsBulkModerateMutationService } from './cleanup-events-mutation-bulk.service';
import { CleanupEventsCheckInRiskSignalsService } from './cleanup-events-check-in-risk-signals.service';
import { CleanupEventsCreateMutationService } from './cleanup-events-mutation-create.service';
import { CleanupEventsPatchMutationService } from './cleanup-events-mutation-patch.service';
import { CleanupEventsMutationsService } from './cleanup-events-mutations.service';
import { CleanupEventsService } from './cleanup-events.service';

@Module({
  imports: [
    AdminRealtimeModule,
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
    CleanupEventsPatchMutationService,
    CleanupEventsBulkModerateMutationService,
    CleanupEventsCreateMutationService,
    CleanupEventsCheckInRiskSignalsService,
    CleanupEventsMutationsService,
    CleanupEventsService,
  ],
})
export class CleanupEventsModule {}
